# Bookrent - Textbook Lending Smart Contract 🗂️

## Overview

Bookrent is an innovative NFT-managed textbook borrowing system built on the Stacks blockchain using Clarity smart contracts. It enables educational institutions, libraries, and students to manage textbook lending through a decentralized, transparent, and efficient system where each textbook is represented as a unique NFT.

## Features

### Core Functionality
- **NFT Textbook Registry**: Each textbook is minted as a unique NFT with metadata
- **Decentralized Lending**: Secure borrowing and returning of textbooks through smart contracts
- **Ownership Tracking**: Complete audit trail of textbook ownership and borrowing history
- **Automated Management**: Smart contract handles lending periods, late fees, and availability
- **Multi-Institution Support**: Support for multiple libraries and educational institutions

### Smart Contracts
- **textbook-nft.clar**: NFT contract for minting and managing textbook tokens
- **lending-manager.clar**: Core lending logic for borrowing, returning, and fee management

## How It Works

1. **Textbook Registration**: Institutions mint NFTs representing their textbook inventory
2. **Borrowing Process**: Students request to borrow available textbooks
3. **Lending Period**: Smart contract manages borrowing duration and due dates  
4. **Return Management**: Automated return processing and availability updates
5. **Fee Handling**: Late fee calculations and payment processing
6. **Ownership History**: Complete on-chain record of all transactions

## Use Cases

- **University Libraries**: Digital management of textbook collections
- **School Districts**: Centralized textbook lending across multiple schools
- **Student Exchanges**: Peer-to-peer textbook sharing between students
- **Rental Services**: Commercial textbook rental platforms
- **Publishing Houses**: Direct-to-consumer textbook lending programs

## Technical Stack

- **Blockchain**: Stacks (Bitcoin L2)
- **Smart Contract Language**: Clarity
- **Token Standard**: SIP-009 NFT Standard
- **Development Framework**: Clarinet
- **Testing**: Vitest

## Getting Started

### Prerequisites
- Clarinet CLI
- Node.js and npm
- Stacks wallet for interaction

### Installation
```bash
git clone https://github.com/kakilinla/bookrent.git
cd bookrent
npm install
```

### Running Tests
```bash
npm test
```

### Contract Deployment
```bash
clarinet check
clarinet deploy
```

## Contract Architecture

### Textbook NFT Contract
Manages the NFT lifecycle for textbooks with features like:
- NFT minting for new textbook entries
- Metadata management (title, author, ISBN, etc.)
- Transfer functionality for ownership changes
- Burn capability for damaged or lost books

### Lending Manager Contract
Handles the borrowing logic with features like:
- Borrowing request processing
- Due date tracking and management
- Late fee calculation and collection
- Return processing and validation
- Borrowing history maintenance

## NFT Metadata Structure

```json
{
  "title": "Introduction to Computer Science",
  "author": "John Smith",
  "isbn": "978-0123456789",
  "publisher": "Tech Books Inc",
  "edition": "5th Edition",
  "year": 2023,
  "condition": "Good",
  "institution": "State University"
}
```

## Key Benefits

### For Institutions
- **Reduced Administrative Overhead**: Automated lending processes
- **Better Asset Tracking**: Real-time inventory management
- **Fraud Prevention**: Immutable borrowing records
- **Cost Efficiency**: Lower operational costs through automation

### For Students
- **Transparent Process**: Clear borrowing terms and conditions
- **Easy Access**: Simplified borrowing and return procedures
- **Fair System**: Equal access to textbook resources
- **Digital Receipts**: Permanent record of all transactions

### For the Ecosystem
- **Interoperability**: Cross-institution textbook sharing
- **Data Integrity**: Tamper-proof transaction records
- **Scalability**: Efficient handling of large textbook collections
- **Innovation**: Foundation for advanced lending features

## Security Features

- **Access Control**: Role-based permissions for different user types
- **Input Validation**: Comprehensive validation of all contract inputs
- **Error Handling**: Robust error management and recovery
- **Audit Trail**: Complete transaction history for accountability

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Write comprehensive tests
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For questions, issues, or feature requests, please open an issue on GitHub.

## Future Enhancements

- Integration with library management systems
- Mobile app for easy textbook browsing and borrowing
- AI-powered recommendation system for textbooks
- Multi-chain compatibility for broader adoption
- Advanced analytics and reporting features
