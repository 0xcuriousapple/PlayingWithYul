pragma solidity >=0.8.0;

contract ERC20 {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    constructor(string memory _name, string memory _symbol, uint256 _decimals) {
        assembly {
            // name
            let lengthOfName := mload(0xe0)
            if iszero(lt(lengthOfName,31)) {revert (0,0)}
            let nameInStack := mload(add(0xe0,0x20))
            let appendedName := or (nameInStack, mul(lengthOfName,2))
            sstore(name.slot, appendedName) 

            // symbol
            let lengthOfSymbol := mload(add(0xe0,0x40))
            if iszero(lt(lengthOfSymbol,31)) {revert (0,0)}
            let symbolInStack := mload(add(0xe0,0x60))
            let appendedSymbol := or (symbolInStack, mul(lengthOfSymbol,2))
            sstore(symbol.slot, appendedSymbol) 

            // decimals
            sstore(decimals.slot, mload(0xc0))
        }
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {

        assembly 
        {
            let start := mload(0x40)
            mstore(start, caller())
            mstore(add(start, 0x20),allowance.slot)
            mstore(add(start, 0x40), keccak256(start, 0x40))

            start := add(start, 0x60)
            mstore(start, spender)
            mstore(add(start, 0x20), mload(sub(start, 0x20)))
            
            let slot := keccak256(start, 0x40)
            sstore(slot, amount)    

            mstore(add(start, 0x60), true)
            return(add(start, 0x60), 0x20)
          
        }
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {

        assembly {
            mstore(0, caller())
            mstore(0x20, balanceOf.slot)
            let slot := keccak256(0, 0x40)
            let balanceOfSender := sload(slot)
            if iszero(or(lt(amount, balanceOfSender), eq(amount, balanceOfSender))) {revert(0,0) }
            sstore(slot, sub(balanceOfSender, amount))

            mstore(0, to)
            slot := keccak256(0, 0x40)
            let balanceOfReceiver := sload(slot)
            sstore(slot, add(balanceOfReceiver, amount))


            mstore(0, true)
            return(0, 0x20)
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {

        assembly{
            // allowance
            let freeMem := mload(0x40)
            mstore(freeMem, from)
            mstore(add(freeMem, 0x20), allowance.slot)
            mstore(add(freeMem, 0x40), keccak256(freeMem, 0x40))

            mstore(add(freeMem,0x60), caller())
            mstore(add(freeMem, 0x80), mload(add(freeMem, 0x40)))

            let slot := keccak256(add(freeMem,0x60), 0x40)
            let allowance_ := sload(slot)
            if iszero(or(gt(allowance_, amount), eq(allowance_, amount))){ revert(0,0) }   

            sstore(slot, sub(allowance_, amount))

            // balance
            mstore(0, from)
            mstore(0x20, balanceOf.slot)
            slot := keccak256(0, 0x40)
            let balanceOfSender := sload(slot)
            if iszero(or(lt(amount, balanceOfSender), eq(amount, balanceOfSender))) {revert(0,0) }
            sstore(slot, sub(balanceOfSender, amount))

            mstore(0, to)
            slot := keccak256(0, 0x40)
            let balanceOfReceiver := sload(slot)
            sstore(slot, add(balanceOfReceiver, amount))


            mstore(0, true)
            return(0, 0x20)
        }
    }

    // /*//////////////////////////////////////////////////////////////
    //                      MINT/BURN LOGIC
    // //////////////////////////////////////////////////////////////*/


    // making this public just for testing
    // ideally this should remain internal or have access control
    function mint(address to, uint256 amount) public {
        assembly {
            sstore(totalSupply.slot, add(sload(totalSupply.slot), amount))
            mstore(0, to)
            mstore(0x20, balanceOf.slot)
            let slot := keccak256(0, 0x40)
            sstore(slot, add(sload(slot), amount))
        } 
    }

    // making this public just for testing
    // ideally this should remain internal or have access control
    function burn(address from, uint256 amount) public {

        assembly {
            sstore(totalSupply.slot, sub(sload(totalSupply.slot), amount))
            mstore(0, from)
            mstore(0x20, balanceOf.slot)
            let slot := keccak256(0, 0x40)
            let balanceOfBurner := sload(slot)
            if iszero(or(lt(amount, balanceOfBurner), eq(amount, balanceOfBurner))) {revert(0,0) }
            sstore(slot, sub(balanceOfBurner, amount))
        } 
    }
}