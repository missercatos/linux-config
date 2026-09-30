# 学习通自动化签到项目 - 完整上下文记忆

## 项目目标
基于 MaaFramework 实现学习通网课的自动签到。最终交付带 UI 的桌面软件，
小白可直接使用。

---

## 已完成的工作

### 1. MaaFramework 原理分析
- 核心原理：截图 → OpenCV/OCR 识别 → 状态机决策 → ADB 模拟操作 → 循环
- 不是录屏回放，是基于视觉的实时识别
- 源码位于 `/home/a/MaaFramework/`
- 详细分析文档：`~/MAA.txt`（1673 行，含完整 Python API 参考）

### 2. Python 环境搭建（Arch Linux）
```bash
# 虚拟环境
python -m venv ~/maa-venv
source ~/maa-venv/bin/activate

# 安装 Python binding
pip install MaaFw==5.12.3

# 下载预编译 C++ 库
curl -L -o /tmp/MAA-linux.zip \
  "https://github.com/MaaXYZ/MaaFramework/releases/download/v5.12.3/MAA-linux-x86_64-v5.12.3.zip"
unzip /tmp/MAA-linux.zip -d /tmp/MAA-linux
cp -r /tmp/MAA-linux/bin ~/maa-bin

# 运行时设置
export MAAFW_BINARY_PATH=~/maa-bin
```

### 3. 环境状态
- `~/maa-venv/` — 已创建，Python 3.14，已装 MaaFw==5.12.3
- `~/maa-bin/` — 已下载完整预编译库（libMaaFramework.so、libopencv_world4 等）
- `~/MAA.txt` — 完整原理分析 + Python API 参考（1673 行）
- 未安装 Android 模拟器

### 4. 已验证的 API
- `Toolkit.init_option()` — ✅ 正常
- `Toolkit.find_adb_devices()` — ✅ 正常（返回空，因为没有设备）
- `AdbController` — ✅ 类加载正常
- `Resource` / `Tasker` — ✅ 类加载正常

---

## 下一步计划

### 短期：搭建 Android 测试环境
1. 安装 Android Studio（AUR: `yay -S android-studio`）
2. 创建 AVD（建议分辨率 1080x1920，DPI 420）
3. 启动 AVD 后验证 ADB：
   ```bash
   ~/Android/Sdk/platform-tools/adb devices
   ```
4. 验证 MaaFramework 检测设备：
   ```bash
   export MAAFW_BINARY_PATH=~/maa-bin
   ~/maa-venv/bin/python3 -c "
   from maa.toolkit import Toolkit
   Toolkit.init_option('./')
   devices = Toolkit.find_adb_devices()
   print(devices)
   "
   ```

### 中期：编写学习通 Pipeline
1. 截图裁剪模板图片（启动页、课程页、签到按钮等）
2. 编写 Pipeline JSON（startup.json、course.json、sign_in.json、popups.json）
3. 测试签到流程

### 长期：打包交付
方案选择：Python + PySide6 GUI + Nuitka 打包
- PySide6 做图形界面（设备选择、任务配置、日志）
- Nuitka 打包成单个可执行文件

### 备选方案：网页版
如果学习通有网页版，用 Playwright 更简单：
- 不需要模拟器
- 不需要模板图片
- DOM 操作比截图识别稳定 10 倍
- 代码量少一半

---

## 关键技术决策

### MaaFramework vs Playwright
| | MaaFramework (ADB) | Playwright (浏览器) |
|--|---|---|
| 操控对象 | Android 模拟器/手机 | Chrome/Firefox 浏览器 |
| 识别方式 | OpenCV 截图匹配 | DOM 选择器 |
| 需要模拟器 | 是 | 否 |
| 需要截图模板 | 是 | 否 |
| 速度 | 较慢（截图识别） | 快（直接操作 DOM） |

**结论：如果学习通支持网页版，优先用 Playwright；如果只有手机 App，用 MaaFramework。**

### Android Studio AVD 兼容性
- AVD 是标准 Android 设备，ADB 完全兼容
- MaaFramework 的 `find_adb_devices()` 能直接检测到 AVD
- 不需要额外配置

---

## 项目文件结构
```
~/maa-bin/                    # 预编译 C++ 库（开发环境用）
~/maa-venv/                   # Python 虚拟环境
~/MAA.txt                     # 完整原理分析 + API 参考
~/chaoxing_bot/               # 项目目录
  ├── main.py                 # 主程序入口
  ├── runtime.py              # 二进制库自动定位模块
  ├── build.sh                # 打包脚本（Nuitka）
  ├── run_dev.sh              # 开发模式运行脚本
  ├── resource/               # 资源目录（打包时自动包含）
  │   ├── pipeline/           # Pipeline JSON
  │   │   ├── startup.json    # 启动和导航
  │   │   ├── sign_in.json    # 签到流程
  │   │   └── popups.json     # 弹窗处理
  │   ├── image/              # 模板图片
  │   └── model/ocr/          # OCR 模型（det.onnx, rec.onnx, keys.txt）
  ├── bin/                    # （打包时自动填充）MaaFramework 库
  └── SKILL.md                # 本文件
```

---

## 打包方案（核心）

### 问题
`~/maa-bin` 是硬编码路径，分发给其他人时他们的机器上没有这个目录。

### 解决方案：runtime.py 自动定位
`runtime.py` 按优先级查找二进制库：
1. 环境变量 `MAAFW_BINARY_PATH`（用户手动指定）
2. 应用目录下的 `bin/`（打包后）
3. `~/maa-bin/`（开发模式备用）

### 打包流程
```bash
cd ~/chaoxing_bot
./build.sh
# 输出在 dist/ 目录，整个目录打包分发
```

### 分发目录结构
```
dist/
├── chaoxing_bot           # 可执行文件（Nuitka 产出）
├── bin/                   # MaaFramework .so 库
│   ├── libMaaFramework.so
│   ├── libMaaToolkit.so
│   ├── libopencv_world4.so.412
│   ├── libonnxruntime.so.1
│   └── ...
├── resource/              # 资源文件
│   ├── pipeline/
│   ├── image/
│   └── model/ocr/
└── *.so                   # 其他依赖库
```

### 用户使用
1. 解压 zip 到任意目录
2. 双击 `chaoxing_bot` 运行
3. 不需要安装 Python、不需要配置环境变量
4. 软件自动从同目录 `bin/` 找到所需库

---

## 参考项目
- MaaXuexi：https://github.com/ravizhan/MaaXuexi （学习强国自动化，最佳参考）
- MaaFwApp：https://github.com/Aliothmoon/MaaFwApp （Android APK 封装）
- MWU：https://github.com/ravizhan/MWU （WebUI 前端）

---

## 注意事项
- Arch Linux 是 PEP 668 保护环境，必须用 venv
- `pip install MaaFw==5.12.3` 不需要克隆仓库，直接从 PyPI 下载
- 预编译库版本必须和 Python binding 版本匹配（都是 v5.12.3）
- 运行前必须 `export MAAFW_BINARY_PATH=~/maa-bin`
