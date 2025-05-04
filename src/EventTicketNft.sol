pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EventTicketNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    // Simple mapping to store token metadata
    mapping(uint256 => string) private _tokenURIs;
    
    mapping(uint256 => uint256) public ticketEventId; // tokenId => eventId
    mapping(uint256 => string) public ticketEventName; // tokenId => eventName
    mapping(uint256 => uint256) public ticketQuantity;
    
    constructor() ERC721("MiniTripPass", "MTP") {}
    
    function mintTicket(
        address to,
        string memory ipfsImageUrl,
        string memory eventName,
        uint256 eventId,
        uint256 quantity
    ) external returns (uint256) {
        uint256 firstTokenId = _tokenIds.current() + 1;
        
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            
            _mint(to, tokenId);
            _tokenURIs[tokenId] = ipfsImageUrl;
            ticketEventId[tokenId] = eventId;
            ticketEventName[tokenId] = eventName;
            ticketQuantity[tokenId] = 1;
        }
        
        return firstTokenId;
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory image = _tokenURIs[tokenId];
        string memory eventName = ticketEventName[tokenId];
        
        uint256 quantity = ticketQuantity[tokenId];
        return string(abi.encodePacked(
            'data:application/json;utf8,{',
                '"name":"Ticket', Strings.toString(tokenId), '",',
                '"description":"Ticket for ', eventName, '",',
                '"image":"', image, '",',
                '"attributes":[{"trait_type":"Event Name","value":"', eventName, '"},',
                '{"trait_type":"Quantity","value":"', Strings.toString(quantity), '"}]',
            '}'
        ));
    }
}