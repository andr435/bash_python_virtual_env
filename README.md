# Python Setup
Script install python packages, virtual enviroment and packet manager, create virtual enviroment and install into it flask project

## 📝 Features
- Automatically installs python required dependencies.  
- Give to user to choose favorite packet and enviroment manager.  
- Automatically create virtual enviroment.  
- Automaticaly install flask packet into virtual enviroment.  


### 🚀 Usage
Run the script with the options:
```bash
./python_machine.sh [-h|v|d] [--help|--version|--directory]
```

### 🛠️ Options:
| Flag | Optional | Description |
|------|----------|-------------|
| -h| --help | Help |
| -v| --version | Script version |
| -d| --directory | Working directory (default ".") |

### Clone the Repository:
```bash
 git clone [https://github.com/ronthesoul/negrovix.git](https://github.com/andr435/bash_python_virtual_env)
 cd negrovix
 chmod +x python_machine.sh
```

### Example Usage
Create an Flask project in /home/<user>/my_project:
```bash
sudo ./python_machine.sh -d /home/<user>/my_project
```

## 🔧 Prerequisites
-  **Operating System**: RedHat-based Linux distributions (RedHat, Rocky, etc.)
-  **Shell**: Bash (must be installed)

## Contributors 
Andrey M. aka andr435
