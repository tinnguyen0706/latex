# LaTeX report template

Template viết báo cáo LaTeX tiếng Việt bằng XeLaTeX và font Times New Roman.
Toàn bộ TeX Live được đóng gói trong Docker, vì vậy máy host không cần cài
TeX Live, XeLaTeX hoặc `latexmk`.

- **Build PDF:** chạy XeLaTeX trong image `latex-times-new-roman:latest`.
- **Format mã nguồn:** chạy `tex-fmt` trực tiếp trên máy host.
- **Editor đề xuất:** Visual Studio Code với extension LaTeX Workshop.
- **PDF mẫu:** `sample/build/main.pdf`.

## 1. Cài công cụ cần thiết

### Windows 10/11

#### 1.1. Cài Git và Visual Studio Code

Mở PowerShell:

```powershell
winget install --id Git.Git -e
winget install --id Microsoft.VisualStudioCode -e
```

Đóng rồi mở lại PowerShell, sau đó kiểm tra:

```powershell
git --version
code --version
```

#### 1.2. Cài Docker Desktop

1. Cài hoặc cập nhật WSL 2 trong PowerShell chạy với quyền Administrator:

   ```powershell
   wsl --install
   wsl --update
   ```

2. Cài [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/).
3. Khi cài đặt, sử dụng backend WSL 2 và Linux containers.
4. Khởi động Docker Desktop, chờ Docker Engine sẵn sàng rồi kiểm tra:

   ```powershell
   docker version
   docker run --rm hello-world
   ```

#### 1.3. Cài formatter `tex-fmt`

Cài binary Windows 64-bit được upstream phát hành qua CTAN:

```powershell
$TexFmtDir = "$env:LOCALAPPDATA\Programs\tex-fmt"
New-Item -ItemType Directory -Force -Path $TexFmtDir | Out-Null
Invoke-WebRequest `
  "https://mirrors.ctan.org/support/latex-formatter/bin/tex-fmt-x86_64-windows.zip" `
  -OutFile "$env:TEMP\tex-fmt.zip"
Expand-Archive -Force "$env:TEMP\tex-fmt.zip" $TexFmtDir

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$TexFmtDir*") {
  [Environment]::SetEnvironmentVariable(
    "Path",
    "$UserPath;$TexFmtDir",
    "User"
  )
}
```

Đóng rồi mở lại PowerShell, sau đó kiểm tra:

```powershell
tex-fmt --version
```

Nếu VS Code không tìm thấy `tex-fmt`, khởi động lại VS Code sau khi cài. File
thực thi nằm trong `%LOCALAPPDATA%\Programs\tex-fmt`.

### Linux (Arch-based)

Các lệnh dưới đây giả định máy đã có một AUR helper là `paru`.

#### 1.1. Cài Git, Docker và Visual Studio Code

```sh
sudo pacman -Syu
sudo pacman -S --needed git docker docker-buildx
paru -S --needed visual-studio-code-bin
```

Bật Docker daemon và cho phép user hiện tại dùng Docker:

```sh
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

Đăng xuất rồi đăng nhập lại để quyền group có hiệu lực, sau đó kiểm tra:

```sh
docker version
docker run --rm hello-world
git --version
code --version
```

#### 1.2. Cài formatter `tex-fmt`

```sh
paru -S --needed tex-fmt-bin
tex-fmt --version
```

Có thể dùng package `tex-fmt` từ AUR thay cho `tex-fmt-bin`; bản `-bin` được
đề xuất vì không phải biên dịch Rust trên máy.

## 2. Lấy source code

Thay `<repository-url>` bằng URL Git của repository này.

### Windows (PowerShell)

```powershell
git clone <repository-url>
cd latex
```

### Linux (Arch-based)

```sh
git clone <repository-url>
cd latex
```

Tất cả các lệnh còn lại phải được chạy từ thư mục gốc `latex/`, trừ khi có ghi
chú khác.

## 3. Chuẩn bị Times New Roman

Docker image yêu cầu đúng bốn file sau trong thư mục `fonts/`:

| File trong project | Kiểu chữ |
| --- | --- |
| `fonts/times.ttf` | Regular |
| `fonts/timesbd.ttf` | Bold |
| `fonts/timesi.ttf` | Italic |
| `fonts/timesbi.ttf` | Bold Italic |

Chỉ sử dụng font khi bạn có quyền sử dụng và phân phối. Không đổi tên một font
khác thành các tên trên: Docker build dùng `fc-scan` để xác nhận từng file thực
sự thuộc family `Times New Roman` và sẽ dừng nếu font không hợp lệ.

### Windows

Nếu Times New Roman đã được cài trong Windows, chạy tại thư mục gốc project:

```powershell
Copy-Item "$env:WINDIR\Fonts\times.ttf"   ".\fonts\times.ttf"
Copy-Item "$env:WINDIR\Fonts\timesbd.ttf" ".\fonts\timesbd.ttf"
Copy-Item "$env:WINDIR\Fonts\timesi.ttf"  ".\fonts\timesi.ttf"
Copy-Item "$env:WINDIR\Fonts\timesbi.ttf" ".\fonts\timesbi.ttf"
```

Nếu Windows lưu font ở vị trí khác, tìm bốn file tương ứng rồi copy thủ công
vào `fonts/` với đúng tên trong bảng.

### Linux (Arch-based)

Times New Roman thường không có sẵn trên Linux. Copy bốn file `.ttf` hợp lệ từ
máy Windows hoặc nguồn mà bạn được cấp phép vào thư mục `fonts/`, sau đó kiểm
tra:

```sh
file fonts/times.ttf fonts/timesbd.ttf fonts/timesi.ttf fonts/timesbi.ttf
```

Việc cài font vào hệ điều hành Linux là không cần thiết vì Dockerfile copy font
trực tiếp vào image.

## 4. Build Docker image

Image chỉ cần build lần đầu, hoặc build lại khi `Dockerfile` hay font thay đổi.
Format và build tài liệu hằng ngày không rebuild image.

### Windows (PowerShell)

Đảm bảo Docker Desktop đang chạy:

```powershell
docker build --build-arg USER_ID=1000 --build-arg GROUP_ID=1000 -t latex-times-new-roman:latest .
```

### Linux (Arch-based)

Truyền UID/GID hiện tại để các file PDF do container sinh ra thuộc quyền sở hữu
của user:

```sh
docker build \
  --build-arg USER_ID="$(id -u)" \
  --build-arg GROUP_ID="$(id -g)" \
  -t latex-times-new-roman:latest .
```

Kiểm tra image đã tồn tại:

```sh
docker image inspect latex-times-new-roman:latest
```

## 5. Cấu hình Visual Studio Code

Cài LaTeX Workshop:

```sh
code --install-extension James-Yu.latex-workshop
```

Mở project:

```sh
code .
```

Sau đó chạy lệnh `Developer: Reload Window` trong Command Palette. Workspace đã
có sẵn `.vscode/settings.json` với các hành vi sau:

- `tex-fmt --nowrap` tự chạy trên host khi lưu file `.tex`;
- recipe mặc định là `XeLaTeX via Docker`;
- Docker chỉ chạy khi build, không chạy khi format;
- file build được ghi vào thư mục `build/` cạnh file TeX gốc;
- auto-build bị tắt để tránh build container sau mỗi lần lưu.

Không cần cài TeX Live hoặc LaTeX Workshop formatter khác trên host.

## 6. Build và xem tài liệu

### Cách đề xuất: LaTeX Workshop

1. Mở file gốc `sample/main.tex`.
2. Nhấn `Ctrl+Alt+B`, hoặc chạy `LaTeX Workshop: Build LaTeX project`.
3. Chạy `LaTeX Workshop: View LaTeX PDF` để xem kết quả.

PDF được tạo tại:

```text
sample/build/main.pdf
```

### Build thủ công trên Windows (PowerShell)

```powershell
docker run --rm `
  --volume "${PWD}:/workspace" `
  --workdir /workspace/sample `
  latex-times-new-roman:latest `
  latexmk -xelatex -interaction=nonstopmode -file-line-error -outdir=build main.tex
```

### Build thủ công trên Linux (Arch-based)

```sh
docker run --rm \
  --volume "$PWD:/workspace" \
  --workdir /workspace/sample \
  latex-times-new-roman:latest \
  latexmk -xelatex -interaction=nonstopmode -file-line-error \
    -outdir=build main.tex
```

Để build tài liệu khác, thay `/workspace/sample` bằng thư mục chứa file TeX gốc
và thay `main.tex` bằng tên file tương ứng.

## 7. Format mã nguồn

VS Code tự format file `.tex` khi lưu. Có thể format thủ công từ terminal:

```sh
tex-fmt --nowrap sample/main.tex
```

Kiểm tra format mà không sửa file:

```sh
tex-fmt --check --nowrap sample/main.tex
```

`tex-fmt` cũng hỗ trợ `.bib`, `.cls` và `.sty`. Dùng comment sau nếu cần giữ
nguyên một đoạn đặc biệt:

```tex
% tex-fmt: off
Đoạn này không bị formatter thay đổi.
% tex-fmt: on
```

## 8. File build và Git

Các file trung gian như `.aux`, `.log`, `.xdv`, `.toc` và `.synctex.gz` đã được
ignore. PDF trong thư mục `build/` vẫn được phép track bằng Git.

Để dọn file trung gian nhưng giữ PDF, chạy:

### Windows (PowerShell)

```powershell
docker run --rm `
  --volume "${PWD}:/workspace" `
  --workdir /workspace/sample `
  latex-times-new-roman:latest `
  latexmk -c -outdir=build main.tex
```

### Linux (Arch-based)

```sh
docker run --rm \
  --volume "$PWD:/workspace" \
  --workdir /workspace/sample \
  latex-times-new-roman:latest \
  latexmk -c -outdir=build main.tex
```

## 9. Xử lý lỗi thường gặp

### `Please set your LaTeX formatter in latex-workshop.formatting.latex`

Đảm bảo bạn mở toàn bộ thư mục project thay vì chỉ mở một file `.tex`, sau đó
chạy `Developer: Reload Window`. Kiểm tra formatter trên host:

```sh
tex-fmt --version
```

### VS Code không tìm thấy `tex-fmt`

Khởi động lại VS Code sau khi cài. Trên Windows, kiểm tra
`%LOCALAPPDATA%\Programs\tex-fmt` có trong biến môi trường `PATH`.

### `permission denied` khi kết nối Docker trên Linux

Kiểm tra daemon và group hiện tại:

```sh
sudo systemctl status docker
id
```

Nếu group `docker` chưa xuất hiện, chạy lại `sudo usermod -aG docker "$USER"`
rồi đăng xuất và đăng nhập lại.

### Docker build báo font không hợp lệ

Kiểm tra lại đủ bốn file và đúng tên. Font phải là Times New Roman thật; file
rỗng, file hỏng hoặc font khác được đổi tên đều bị Dockerfile từ chối.

### Build không dùng image mới

Build lại image với đúng tag mà LaTeX Workshop đang dùng:

```sh
docker build -t latex-times-new-roman:latest .
```

Trên Linux nên dùng lại lệnh đầy đủ ở mục **Build Docker image** để giữ đúng
UID/GID.
