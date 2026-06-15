# DeepSeek CLI 🚀

---

## English Version 🇬🇧

A powerful command-line interface for DeepSeek API with full chat mode, conversation management, and secure command execution.

### ✨ Features

- 💬 **Full Interactive Chat** - Like ChatGPT in your terminal
- 📜 **Conversation History** - All chats are saved automatically
- 🔄 **Multiple Sessions** - Switch between different chat sessions
- 💾 **Auto Save & Load** - Continue previous conversations seamlessly
- 🔧 **Safe Command Execution** - With user confirmation
- 🎨 **Beautiful UI** - Rich library support for colors and formatting
- 📦 **One-Line Install** - No complex setup required
- 🔑 **API Key Management** - Secure key storage

### 📋 Prerequisites

- Python 3.8 or higher
- curl
- Internet connection for API access

### 🚀 Quick Install

```bash
curl -fsSL https://github.com/user-attachments/files/28942495/install.sh | bash
```

After installation, close and reopen your terminal or run:
```bash
source ~/.bashrc  
source ~/.zshrc   
```

### 🔑 Initial Setup

Get your API key from [DeepSeek Platform](https://platform.deepseek.com/api_keys):

```bash
deepseek-cli --set-api-key sk-xxxxxxxxxxxxxxxx
```

### 🎮 Usage Guide

**Start Interactive Chat:**
```bash
deepseek-cli
```

**Single Question Mode:**
```bash
deepseek-cli ask "How do I find all Python files in a directory?"
```

**Auto-execute Commands (with caution):**
```bash
deepseek-cli ask "Create a file called hello.txt" --yes
```

### ⌨️ Chat Commands

| Command | Description |
|---------|-------------|
| `/new` | Start a new conversation |
| `/list` | List all saved chats |
| `/load <id>` | Load a previous chat |
| `/save` | Manually save current chat |
| `/history` | View recent conversation history |
| `/clear` | Clear current conversation |
| `/exit` | Exit chat mode |

### 📁 File Structure

```
~/.deepseek/
├── config.json          # Settings and API key
├── chats/               # Chat storage folder
│   ├── 20241210_143022.json
│   ├── 20241210_150315.json
│   └── ...
└── current_chat.json    # Last active chat
```

### 🛡️ Security Features

- **Pre-execution Confirmation** - No command runs without permission
- **Secure Key Storage** - Config file saved with 600 permissions
- **Safe System Prompt** - Instructs model to avoid dangerous commands

### 🔧 Customization

Edit `~/.deepseek/config.json`:

```json
{
  "api_key": "sk-xxx",
  "model": "deepseek-chat",
  "temperature": 0.7,
  "max_tokens": 2000,
  "use_rich": true
}
```

### 🐛 Troubleshooting

**"command not found" error:**
```bash
export PATH="$HOME/.deepseek/bin:$PATH"
```

**"API key not set" error:**
```bash
deepseek-cli --set-api-key YOUR_KEY
```

### 📝 Examples

```bash
# Programming help
deepseek-cli ask "Write a Python decorator to measure function execution time"

# File management
deepseek-cli ask "Find all log files older than 30 days"

# Linux learning
deepseek-cli ask "Explain the difference between grep and find with examples"
```


## نسخه فارسی 🇮🇷

یک رابط خط فرمان قدرتمند و تعاملی برای API دیپ‌سیک با قابلیت چت کامل، مدیریت مکالمات و اجرای امن دستورات.

### ✨ قابلیت‌ها

- 💬 **چت تعاملی کامل** - مثل ChatGPT توی ترمینال
- 📜 **حفظ تاریخچه مکالمات** - تمام چت‌ها ذخیره می‌شن
- 🔄 **چندین جلسه همزمان** - بین چت‌ها جابجا شو
- 💾 **ذخیره و لود خودکار** - ادامه دادن چت‌های قبلی
- 🔧 **اجرای امن دستورات** - با تأیید کاربر
- 🎨 **رابط کاربری زیبا** - پشتیبانی از Rich library برای رنگ‌بندی
- 📦 **نصب یک خطی** - بدون نیاز به تنظیمات پیچیده
- 🔑 **مدیریت API Key** - ذخیره امن کلید

### 📋 پیش‌نیازها

- Python 3.8 یا بالاتر
- curl
- اینترنت برای دسترسی به API

### 🚀 نصب سریع

```bash
curl -fsSL https://github.com/user-attachments/files/28942495/install.sh | bash
```

بعد از نصب، ترمینال رو ببند و دوباره باز کن:
```bash
source ~/.bashrc  
source ~/.zshrc   
```

### 🔑 تنظیم اولیه

API key خودت رو از [دیپ‌سیک پلتفرم](https://platform.deepseek.com/api_keys) بگیر:

```bash
deepseek-cli --set-api-key sk-xxxxxxxxxxxxxxxx
```

### 🎮 نحوه استفاده

**شروع چت تعاملی:**
```bash
deepseek-cli
```

**سوال یک خطی:**
```bash
deepseek-cli ask "چطور می‌تونم همه فایل‌های پایتون رو توی یه پوشه پیدا کنم؟"
```

**اجرای خودکار دستورات (با احتیاط):**
```bash
deepseek-cli ask "یه فایل hello.txt بساز" --yes
```

### ⌨️ دستورات داخل چت

| دستور | توضیحات |
|-------|---------|
| `/new` | شروع چت جدید |
| `/list` | لیست همه چت‌های ذخیره شده |
| `/load <id>` | لود کردن یک چت قبلی |
| `/save` | ذخیره دستی چت فعلی |
| `/history` | دیدن تاریخچه اخیر |
| `/clear` | پاک کردن چت فعلی |
| `/exit` | خروج از چت |

### 📁 ساختار فایل‌ها

```
~/.deepseek/
├── config.json          # تنظیمات و API key
├── chats/               # پوشه ذخیره چت‌ها
│   ├── 20241210_143022.json
│   ├── 20241210_150315.json
│   └── ...
└── current_chat.json    # آخرین چت فعال
```

### 🛡️ امنیت

- **تأیید قبل از اجرا** - هیچ دستوری بدون اجازه اجرا نمی‌شه
- **ذخیره امن کلید** - فایل config با دسترسی 600 ذخیره می‌شه
- **سیستم پرامپت ایمن** - به مدل می‌گه دستورات مخرب پیشنهاد نده

### 🔧 شخصی‌سازی

ویرایش فایل `~/.deepseek/config.json`:

```json
{
  "api_key": "sk-xxx",
  "model": "deepseek-chat",
  "temperature": 0.7,
  "max_tokens": 2000,
  "use_rich": true
}
```

### 🐛 عیب‌یابی

**خطای "command not found":**
```bash
export PATH="$HOME/.deepseek/bin:$PATH"
```

**خطای "API key not set":**
```bash
deepseek-cli --set-api-key YOUR_KEY
```

### 📝 مثال‌ها

```bash
# کمک در برنامه‌نویسی
deepseek-cli ask "یه دکوریتور پایتون بنویس برای اندازه‌گیری زمان اجرای تابع"

# مدیریت فایل‌ها
deepseek-cli ask "همه فایل‌های log قدیمی‌تر از 30 روز رو پیدا کن"

# یادگیری لینوکس
deepseek-cli ask "فرق بین grep و find رو توضیح بده با مثال"
```
