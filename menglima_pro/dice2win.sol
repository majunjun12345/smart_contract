pragma solidity ^0.4.23;

// placeBet 放注
// settlebet 清算
// commit 随机的 256位 数字，用来唯一标识一次赌注

// * dice2.win - fair games that pay Ether.
//
// * Ethereum smart contract, deployed at 0xD1CEeeefA68a6aF0A5f6046132D986066c7f9426.
//
// 使用双重保障，防止被玩家、房主和矿工篡改，除了完全透明以外，还允许任意高的赌注
// * Uses hybrid commit-reveal + block hash random number generation that is immune
//   to tampering by players, house and miners. Apart from being fully transparent,
//   this also allows arbitrarily high bets.
//
// * Refer to https://dice2.win/whitepaper.pdf for detailed description and proofs.

contract Dice2Win {
    /// *** Constants section

    /*
        每次赌注都会向庄家缴纳 1% 的手续费，但是有个最小值，为 0.0003 以太币
        最小金额由赌注交易所花费的 gas 决定，最高 10G wei
    */

    // Each bet is deducted 1% in favour of the house, but no less than some minimum.
    // The lower bound is dictated by gas costs of the settleBet transaction, providing
    // headroom for up to 10 Gwei prices.
    uint constant HOUSE_EDGE_PERCENT = 1;
    uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;

    // 低于此金额的投注不能参与头奖，也不会扣除头奖费(0.001)
    // Bets lower than this amount do not participate in jackpot rolls (and are
    // not deducted JACKPOT_FEE).
    uint constant MIN_JACKPOT_BET = 0.1 ether;

    // 赢得头奖的概率(0.1%)和向头奖池缴纳的费用
    // Chance to win jackpot (currently 0.1%) and fee deducted into jackpot fund.
    uint constant JACKPOT_MODULO = 1000;
    uint constant JACKPOT_FEE = 0.001 ether;

    // 最小赌注和最大赌注
    // There is minimum and maximum bets.
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether;

    /* 
    Modulo 是在任何游戏中出现的等概率的数字(可能就是指概率)
    2 抛硬币
    6 掷骰子
    36 掷两次骰子
    100 以太过山车
    37 轮盘赌

    选择哪种 modulo 就是选择哪种游戏
    */
    // Modulo is a number of equiprobable outcomes in a game:
    //  - 2 for coin flip
    //  - 6 for dice
    //  - 6*6 = 36 for double dice
    //  - 100 for etheroll
    //  - 37 for roulette
    //  etc.
    /*
        之所以这么称呼是因为256位熵被视为一个巨大的整数，其除以模数的余数被视为下注结果。
    */
    // It's called so because 256-bit entropy is treated like a huge integer and
    // the remainder of its division by modulo is considered bet outcome.
    uint constant MAX_MODULO = 100;

    /*  
        threshold: 阙值
        bit mask: 位掩码
        endian: 字节序
        modulo 6, 101000 表示押注 4 和 6
    
        低于此阙值的 modulos, 将会和位掩码进行对照检查，从而允许投注任何的组合结果。
        例如，玩 modulo 为 6 的单个骰子游戏，掩码为 101000（base-2，big endian）意味着投注 4 和 6 
        如果 modulo 高于阙值(etheroll 为最高 100)，将会有一个小小的限制，从而允许能够对任意范围的结果下注
    */

    // For modulos below this threshold rolls are checked against a bit mask,
    // thus allowing betting on any combination of outcomes. For example, given
    // modulo 6 for dice, 101000 mask (base-2, big endian) means betting on
    // 4 and 6; for games with modulos higher than threshold (Etheroll), a simple
    // limit is used, allowing betting on any outcome in [0, N) range.
    /*
        具体值取决于 256 位的中间乘法
        允许对高达42位的数字有效地实现人口计数
        40 是 42 以下 8 的最大倍数
    */
    // The specific value is dictated by the fact that 256-bit intermediate
    // multiplication result allows implementing population count efficiently
    // for numbers that are up to 42 bits, and 40 is the highest multiple of
    // eight below 42.
    uint constant MAX_MASK_MODULO = 40;

    // 这是对投注掩码的溢出检查
    // This is a check on bet mask overflow.
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

    /*
        EVM 区块hash 操作码 可以查询过去不超过 256 个块。

        鉴于settleBet使用placeBet的块hash作为互补熵源之一，我们不能处理高于此阙值的堵住

        在极少数情况下，由于技术原因或以太仿拥塞，dice2win 的庄家机器人会调用 settleBet 失败。
        此类投注可以通过调用 refundBet 进行退款

    */
    // EVM BLOCKHASH opcode can query no further than 256 blocks into the
    // past. Given that settleBet uses block hash of placeBet as one of
    // complementary entropy sources, we cannot process bets older than this
    // threshold. On rare occasions dice2.win croupier may fail to invoke
    // settleBet in this timespan due to technical issues or extreme Ethereum
    // congestion; such bets can be refunded via invoking refundBet.
    uint constant BET_EXPIRATION_BLOCKS = 250;


    /*
        一些无效的地址用来初始化 秘密签名
        强制维护人员在处理任何下注之前调用 setSecretSigner
    */
    // Some deliberately invalid address to initialize the secret signer with.
    // Forces maintainers to invoke setSecretSigner before processing any bets.
    address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // 标准的合约所有者转移
    // Standard contract ownership transfer.
    address public owner;
    address private nextOwner;

    // 可调整的最大赌注利润。 用于限制动态赔率的投注。
    // Adjustable max bet profit. Used to cap bets against dynamic odds.
    uint public maxProfit;

    // 私钥对应的地址，私钥用来给的 placeBet 的赌注提交签名
    // The address corresponding to a private key used to sign placeBet commits.
    address public secretSigner;

    // 头奖奖池积累的奖金
    // Accumulated jackpot fund.
    uint128 public jackpotSize;

    // 被锁定在潜在获胜赌注中的资金，用来防止合约没有充足资金支付
    // Funds that are locked in potentially winning bets. Prevents contract from
    // committing to bets it cannot pay out.
    uint128 public lockedInBets;

    // 单个赌注的结构
    // A structure representing a single bet.
    struct Bet {
        /*
            赌金
            游戏对应的 modulo
            获胜的数量，用来计算获奖金额
            放注的区块号码
            掩码，代表赢得赌局结果
            赌徒的地址，用来支付赌赢的奖金
        */
        // Wager amount in wei.
        uint amount;
        // Modulo of a game.
        uint8 modulo;
        // Number of winning outcomes, used to compute winning payment (* modulo/rollUnder),
        // and used instead of mask for games with modulo > MAX_MASK_MODULO.
        uint8 rollUnder;
        // Block number of placeBet tx.
        uint40 placeBlockNumber;
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        uint40 mask;
        // Address of a gambler, used to pay out winning bets.
        address gambler;
    }

    // 赌注提交 和 赌注状态的对应关系，commit 可能就是对应赌注的一个 id（随机的 256 位数）
    // Mapping from commits to all currently active & processed bets.
    mapping (uint => Bet) bets;

    // 事件 用来使统计更容易
    // Events that are issued to make statistic recovery easier.
    event FailedPayment(address indexed beneficiary, uint amount);
    event Payment(address indexed beneficiary, uint amount);
    event JackpotPayment(address indexed beneficiary, uint amount);

    // Constructor. Deliberately does not take any parameters.
    constructor () public {
        owner = msg.sender;
        secretSigner = DUMMY_ADDRESS;
    }

    // 装饰器，限制条件，仅限于合约拥有者调用
    // Standard modifier on methods invokable only by contract owner.
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    // 所有权转移策略
    // Standard contract ownership transfer implementation,
    function approveNextOwner(address _nextOwner) external onlyOwner {
        require (_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }
    function acceptNextOwner() external {
        require (msg.sender == nextOwner, "Can only accept preapproved new owner.");
        owner = nextOwner;
    }

    // 备用函数，故意留空，主要用途是给账户充值
    // Fallback function deliberately left empty. It's primary use case
    // is to top up the bank roll.
    function () public payable {
    }

    // See comment for "secretSigner" variable.
    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

    // 更改最大赌注奖励。 将此设置为零可有效禁用投注。
    // Change max bet reward. Setting this to zero effectively disables betting.
    function setMaxProfit(uint _maxProfit) public onlyOwner {
        require (_maxProfit < MAX_AMOUNT, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
    }

    // 此函数用于提高头奖奖金。 只能增加不能减少
    // This function is used to bump up the jackpot fund. Cannot be used to lower it.
    function increaseJackpot(uint increaseAmount) external onlyOwner {
        require (increaseAmount <= address(this).balance, "Increase amount larger than balance.");
        require (jackpotSize + lockedInBets + increaseAmount <= address(this).balance, "Not enough funds.");
        jackpotSize += uint128(increaseAmount);
    }

    // 支付 dice2.win 的操作费用
    // Funds withdrawal to cover costs of dice2.win operation.
    function withdrawFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
        require (jackpotSize + lockedInBets + withdrawAmount <= address(this).balance, "Not enough funds.");
        sendFunds(beneficiary, withdrawAmount, withdrawAmount);
    }

    // 只有在没有人进行投注时，无论是已结算还是已退款，合约才会被会被销毁。所有的金额都将被合约的所属者拥有
    // Contract may be destroyed only when there are no ongoing bets,
    // either settled or refunded. All funds are transferred to contract owner.
    function kill() external onlyOwner {
        require (lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        selfdestruct(owner);
    }


    // 投注逻辑
    /// *** Betting logic

    // Bet states:
    //  amount == 0 && gambler == 0 - 'clean' (can place a bet)                可以下注
    //  amount != 0 && gambler != 0 - 'active' (can be settled or refunded)    可以结算或退款
    //  amount == 0 && gambler != 0 - 'processed' (can clean storage)          可能是该赌局已经完成，可清除存储的相关信息

    // Bet placing transaction - issued by the player.                         投注交易 - 由玩家发起
    //  betMask         - bet outcomes bit mask for modulo <= MAX_MASK_MODULO,  打赌结果的位掩码，小于最大的位掩码
    //                    [0, betMask) for larger modulos.
    //  modulo          - game modulo.
    //  commitLastBlock - number of the maximum block where "commit" is still considered valid.   最大快数量，commit 状态依旧被认为是有效的
    
    /*
        Keccak256哈希的一些秘密“揭示”随机数，由settleBet交易中的dice2.win croupier bot提供。
        提供“提交”确保在开始放置placeBet后不能在幕后更改。
    */
    //  commit          - Keccak256 hash of some secret "reveal" random number, to be supplied
    //                    by the dice2.win croupier bot in the settleBet transaction. Supplying
    //                    "commit" ensures that "reveal" cannot be changed behind the scenes
    //                    after placeBet have been mined.
    //  r, s            - components of ECDSA signature of (commitLastBlock, commit). v is       ECDSA签名的组成部分
    //                    guaranteed to always equal 27.                                         v 总是等于 27
    //

    // Commit，基本上是随机的256位数，用作'bets'映射中的唯一投注标识符。
    // Commit, being essentially random 256-bit number, is used as a unique bet identifier in
    // the 'bets' mapping.
    //
    /*
        commits 和 block 绑定，以确保最多使用一次；否则，矿工将可能通过已知的 commit/reveal 进行下注，而且可能会更改 blockhash
        croupier 会始终确保 commitLastBlock 不大于 placeBet block number 加上 BET_EXPIRATION_BLOCKS
    */
    // Commits are signed with a block limit to ensure that they are used at most once - otherwise
    // it would be possible for a miner to place a bet with a known commit/reveal pair and tamper
    // with the blockhash. Croupier guarantees that commitLastBlock will always be not greater than
    // placeBet block number plus BET_EXPIRATION_BLOCKS. See whitepaper for details.
    function placeBet(uint betMask, uint modulo, uint commitLastBlock, uint commit, bytes32 r, bytes32 s) external payable {
        // Check that the bet is in 'clean' state.
        Bet storage bet = bets[commit];
        require (bet.gambler == address(0), "Bet should be in a 'clean' state.");

        // Validate input data ranges.
        uint amount = msg.value;
        require (modulo > 1 && modulo <= MAX_MODULO, "Modulo should be within range.");
        require (amount >= MIN_BET && amount <= MAX_AMOUNT, "Amount should be within range.");
        require (betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");

        // Check that commit is valid - it has not expired and its signature is valid.
        require (block.number <= commitLastBlock, "Commit has expired.");
        bytes32 signatureHash = keccak256(abi.encodePacked(uint40(commitLastBlock), commit));
        require (secretSigner == ecrecover(signatureHash, 27, r, s), "ECDSA signature is not valid.");

        uint rollUnder;
        uint mask;

        if (modulo <= MAX_MASK_MODULO) {
            // Small modulo games specify bet outcomes via bit mask.
            // rollUnder is a number of 1 bits in this mask (population count).
            // This magic looking formula is an efficient way to compute population
            // count on EVM for numbers below 2**40. For detailed proof consult
            // the dice2.win whitepaper.
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        } else {
            // Larger modulos specify the right edge of half-open interval of
            // winning bet outcomes.
            require (betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollUnder = betMask;
        }

        // Winning amount and jackpot increase.
        uint possibleWinAmount;
        uint jackpotFee;

        (possibleWinAmount, jackpotFee) = getDiceWinAmount(amount, modulo, rollUnder);

        // Enforce max profit limit.
        require (possibleWinAmount <= amount + maxProfit, "maxProfit limit violation.");

        // Lock funds.
        lockedInBets += uint128(possibleWinAmount);
        jackpotSize += uint128(jackpotFee);

        // Check whether contract has enough funds to process this bet.
        require (jackpotSize + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");

        // Store bet parameters on blockchain.
        bet.amount = amount;
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.placeBlockNumber = uint40(block.number);
        bet.mask = uint40(mask);
        bet.gambler = msg.sender;
    }

    /*
        交易处理 - 理论上任何人都能够处理，但是在设计上只能被 dice2.win 庄家机器人处理。
        为了处理具有特定 'commit' 的赌注，settleBet 接口应当提供一个 'reveal' 数字，这个数字应当和 'commit' 的 Keccak256 哈希值相等
        clean_commit 是以前已经被处理过的赌注，将会被转换为 'clean' 状态，以防止区块链膨胀并退换一些 gas
    */

    // Settlement transaction - can in theory be issued by anyone, but is designed to be
    // handled by the dice2.win croupier bot. To settle a bet with a specific "commit",
    // settleBet should supply a "reveal" number that would Keccak256-hash to
    // "commit". clean_commit is some previously 'processed' bet, that will be moved into
    // 'clean' state to prevent blockchain bloat and refund some gas.
    function settleBet(uint reveal, uint cleanCommit) external {
        // "commit" for bet settlement can only be obtained by hashing a "reveal".
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        // Fetch bet parameters into local variables (to save gas).
        Bet storage bet = bets[commit];
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        uint placeBlockNumber = bet.placeBlockNumber;
        address gambler = bet.gambler;

        // Check that bet is in 'active' state.
        require (amount != 0, "Bet should be in an 'active' state");

        // 只能查阅最近 256 个区块的 hash 值
        // Check that bet has not expired yet (see comment to BET_EXPIRATION_BLOCKS).
        require (block.number > placeBlockNumber, "settleBet in the same block as placeBet, or before.");
        require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

        // Move bet into 'processed' state already.
        bet.amount = 0;

        // The RNG - combine "reveal" and blockhash of placeBet using Keccak256. Miners
        // are not aware of "reveal" and cannot deduce it from "commit" (as Keccak256
        // preimage is intractable), and house is unable to alter the "reveal" after
        // placeBet have been mined (as Keccak256 collision finding is also intractable).
        bytes32 entropy = keccak256(abi.encodePacked(reveal, blockhash(placeBlockNumber)));

        // Do a roll by taking a modulo of entropy. Compute winning amount.
        uint dice = uint(entropy) % modulo;

        uint diceWinAmount;
        uint _jackpotFee;
        (diceWinAmount, _jackpotFee) = getDiceWinAmount(amount, modulo, rollUnder);

        uint diceWin = 0;
        uint jackpotWin = 0;

        // Determine dice outcome.
        if (modulo <= MAX_MASK_MODULO) {
            // For small modulo games, check the outcome against a bit mask.
            if ((2 ** dice) & bet.mask != 0) {
                diceWin = diceWinAmount;
            }

        } else {
            // For larger modulos, check inclusion into half-open interval.
            if (dice < rollUnder) {
                diceWin = diceWinAmount;
            }

        }

        // Unlock the bet amount, regardless of the outcome.
        lockedInBets -= uint128(diceWinAmount);

        // Roll for a jackpot (if eligible).
        if (amount >= MIN_JACKPOT_BET) {
            // The second modulo, statistically independent from the "main" dice roll.
            // Effectively you are playing two games at once!
            uint jackpotRng = (uint(entropy) / modulo) % JACKPOT_MODULO;

            // Bingo!
            if (jackpotRng == 0) {
                jackpotWin = jackpotSize;
                jackpotSize = 0;
            }
        }

        // Log jackpot win.
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin);
        }

        // Send the funds to gambler.
        sendFunds(gambler, diceWin + jackpotWin == 0 ? 1 wei : diceWin + jackpotWin, diceWin);

        // Clear storage of some previous bet.
        if (cleanCommit == 0) {
            return;
        }

        clearProcessedBet(cleanCommit);
    }

    /*
        退款交易 - 由于时间到期，将返还未处理的赌金；
        由于 EVM 的限制，还不能处理这样的区块。
        如果您发现自己处于这样的情况，请联系 dice2.win 获得技术支持
        但是没有什么可以阻止你调用这个方法
    */

    // Refund transaction - return the bet amount of a roll that was not processed in a
    // due timeframe. Processing such blocks is not possible due to EVM limitations (see
    // BET_EXPIRATION_BLOCKS comment above for details). In case you ever find yourself
    // in a situation like this, just contact the dice2.win support, however nothing
    // precludes you from invoking this method yourself.
    function refundBet(uint commit) external {
        // Check that bet is in 'active' state.
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require (amount != 0, "Bet should be in an 'active' state");

        // Check that bet has already expired.
        require (block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

        // Move bet into 'processed' state, release funds.
        bet.amount = 0;

        uint diceWinAmount;
        uint jackpotFee;
        (diceWinAmount, jackpotFee) = getDiceWinAmount(amount, bet.modulo, bet.rollUnder);

        lockedInBets -= uint128(diceWinAmount);
        jackpotSize -= uint128(jackpotFee);

        // Send the refund.
        sendFunds(bet.gambler, amount, amount);
    }

    // 批量清除存储的辅助程序
    // A helper routine to bulk clean the storage.
    function clearStorage(uint[] cleanCommits) external {
        uint length = cleanCommits.length;

        for (uint i = 0; i < length; i++) {
            clearProcessedBet(cleanCommits[i]);
        }
    }

    // 将 'processed' 的赌注状态变为 'clean' 状态
    // Helper routine to move 'processed' bets into 'clean' state.
    function clearProcessedBet(uint commit) private {
        Bet storage bet = bets[commit];

        // Do not overwrite active bets with zeros; additionally prevent cleanup of bets
        // for which commit signatures may have not expired yet (see whitepaper for details).
        if (bet.amount != 0 || block.number <= bet.placeBlockNumber + BET_EXPIRATION_BLOCKS) {
            return;
        }

        // Zero out the remaining storage (amount was zeroed before, delete would consume 5k
        // more gas).
        bet.modulo = 0;
        bet.rollUnder = 0;
        bet.placeBlockNumber = 0;
        bet.mask = 0;
        bet.gambler = address(0);
    }

    // 减去庄家优势后所赢得的赌金
    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(uint amount, uint modulo, uint rollUnder) private pure returns (uint winAmount, uint jackpotFee) {
        require (0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");

        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

        uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;

        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }

        require (houseEdge + jackpotFee <= amount, "Bet doesn't even cover house edge.");
        winAmount = (amount - houseEdge - jackpotFee) * modulo / rollUnder;
    }

    // 处理付款的辅助程序
    // Helper routine to process the payment.
    function sendFunds(address beneficiary, uint amount, uint successLogAmount) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, successLogAmount);
        } else {
            emit FailedPayment(beneficiary, amount);
        }
    }

    // 请参阅白皮书了解其背后的含义
    // This are some constants making O(1) population count in placeBet possible.
    // See whitepaper for intuition and proofs behind it.
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;
}