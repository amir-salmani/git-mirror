# Git Mirror Tool 🔄

A robust bash script for mirroring Git repositories while preserving branches, tags, and handling branch protection rules. Perfect for maintaining backups or migrating between Git providers.

## Features

- Mirror repositories between any Git providers (GitHub, GitLab, Bitbucket, etc.)
- Support for multiple authentication methods (username/password, access tokens)
- Handles protected branches by creating timestamped mirror branches
- Comprehensive logging and operation summaries
- Support for HTTPS and SSH protocols
- Clean error handling and user feedback
- Zero external dependencies beyond Git

## Prerequisites

- Git (2.0 or newer)
- Bash shell environment
- Basic read/write permissions on source and destination repositories

## Installation

1. Clone this repository or download the script:
   ```bash
   git clone https://github.com/yourusername/git-mirror-tool.git
   ```

2. Make the script executable:
   ```bash
   chmod +x git-mirror.sh
   ```

3. Optionally, move it to your PATH:
   ```bash
   sudo mv git-mirror.sh /usr/local/bin/git-mirror
   ```

## Usage

Simply run the script and follow the interactive prompts:

```bash
./git-mirror.sh
```

The tool will guide you through:
1. Source repository configuration
2. Destination repository configuration
3. Authentication setup (if needed)
4. Mirroring process

### Logging

The tool generates two types of log files in the current directory:
- `git_mirror_YYYYMMDD_HHMMSS.log`: Detailed operation logs
- `git_mirror_summary_YYYYMMDD_HHMMSS.txt`: Operation summary and results

## Examples

### Mirror from GitHub to GitLab
```bash
$ ./git-mirror.sh
Enter source repository URL: https://github.com/user/repo.git
Enter destination repository URL: https://gitlab.com/user/repo.git
```

### Mirror using SSH
```bash
$ ./git-mirror.sh
Enter source repository URL: git@github.com:user/repo.git
Enter destination repository URL: git@gitlab.com:user/repo.git
```

## Known Limitations

- Branch protection rules on the destination repository may prevent direct pushes
- SSH key authentication must be properly configured on your system
- Large repositories may take significant time to mirror

## Troubleshooting

- **Authentication Fails**: Ensure your credentials or tokens have sufficient permissions
- **SSH Issues**: Verify your SSH keys are properly configured
- **Protected Branches**: Check the logs for branches that couldn't be pushed directly

## Contributing

Feel free to submit issues and pull requests. All contributions are welcome!

## Development Notes

This tool was developed using VS Code with the assistance of the Roo Code extension and Claude AI for code review and optimization. While AI tools helped improve code quality and documentation, the core implementation and testing were done manually to ensure reliability and real-world usability.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Thanks to the Git community for the comprehensive documentation
- VS Code Roo Code extension for code suggestions
- Claude AI for code review assistance
- Everyone who's tested and provided feedback

## Author

Your Name ([@amir-salmani](https://github.com/amir-salmani))

---

*Last updated: February 2025*