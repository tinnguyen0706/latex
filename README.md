# LaTeX report template

Project dùng XeLaTeX và Times New Roman để viết báo cáo LaTeX tiếng Việt. Image
cũng hỗ trợ class `acmart` 2.19 cho bản review và bản xuất bản ACM CHI. TeX Live,
XeLaTeX và `latexmk` nằm trong Docker image private; máy host chỉ cần Docker,
Visual Studio Code, LaTeX Workshop và formatter `tex-fmt`.

```text
Source: https://github.com/tinnguyen0706/latex
Image:  ghcr.io/tinnguyen0706/latex-times-new-roman:latest
PDF:    sample/build/main.pdf
```

> Repository và Docker image đều private. Tài khoản GitHub của bạn phải được
> cấp quyền truy cập trước khi clone hoặc pull image.

## Thứ tự cài đặt

1. Cài Git, GitHub CLI, VS Code, Docker và `tex-fmt`.
2. Đăng nhập GitHub và clone source code.
3. Đăng nhập GHCR và pull Docker image.
4. Cài LaTeX Workshop, mở project và reload VS Code.
5. Mở `sample/main.tex` rồi build PDF.

Không cần cài TeX Live, MiKTeX, XeLaTeX hoặc `latexmk` trực tiếp trên máy.

## 1. Cài công cụ

### Windows 10/11

#### Git, GitHub CLI và Visual Studio Code

Mở PowerShell:

```powershell
winget install --id Git.Git -e
winget install --id GitHub.cli -e
winget install --id Microsoft.VisualStudioCode -e
```

Đóng rồi mở lại PowerShell và kiểm tra:

```powershell
git --version
gh --version
code --version
```

#### Docker Desktop

1. Mở PowerShell bằng quyền Administrator và cài/cập nhật WSL 2:

   ```powershell
   wsl --install
   wsl --update
   ```

2. Cài [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/).
3. Dùng backend WSL 2 và Linux containers.
4. Khởi động Docker Desktop, chờ Docker Engine sẵn sàng rồi kiểm tra:

   ```powershell
   docker version
   docker run --rm hello-world
   ```

#### Formatter `tex-fmt`

Project dùng `tex-fmt` trên host để format khi lưu file. Cài binary Windows
64-bit bằng PowerShell:

```powershell
$TexFmtDir = "$env:LOCALAPPDATA\Programs\tex-fmt"
New-Item -ItemType Directory -Force -Path $TexFmtDir | Out-Null
Invoke-WebRequest `
  "https://mirrors.ctan.org/support/latex-formatter/bin/tex-fmt-x86_64-windows.zip" `
  -OutFile "$env:TEMP\tex-fmt.zip"
Expand-Archive -Force "$env:TEMP\tex-fmt.zip" $TexFmtDir

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$TexFmtDir*") {
  [Environment]::SetEnvironmentVariable("Path", "$UserPath;$TexFmtDir", "User")
}
```

Đóng rồi mở lại PowerShell:

```powershell
tex-fmt --version
```

### Linux (Arch-based)

Các lệnh dưới đây dùng AUR helper `paru`:

```sh
sudo pacman -Syu
sudo pacman -S --needed git github-cli docker docker-buildx
paru -S --needed visual-studio-code-bin tex-fmt-bin
```

Bật Docker và cho phép user hiện tại sử dụng Docker:

```sh
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

Đăng xuất rồi đăng nhập lại để quyền group có hiệu lực. Sau đó kiểm tra:

```sh
git --version
gh --version
code --version
tex-fmt --version
docker version
docker run --rm hello-world
```

## 2. Đăng nhập GitHub và clone source code

Các lệnh sau dùng được trong PowerShell và shell trên Linux:

```sh
gh auth login --hostname github.com --git-protocol https --web --scopes "repo,read:packages"
gh repo clone tinnguyen0706/latex
cd latex
```

Khi đăng nhập, GitHub CLI sẽ hiển thị mã một lần và địa chỉ
`https://github.com/login/device`. Mở địa chỉ đó, nhập mã và cấp quyền.

Kiểm tra repository:

```sh
git remote -v
git status
```

Tất cả lệnh tiếp theo được chạy từ thư mục gốc `latex/`.

## 3. Đăng nhập GHCR và pull image

Image chứa Times New Roman nên được lưu private. Dùng token của GitHub CLI để
đăng nhập Docker; thay `YOUR_GITHUB_USERNAME` bằng username GitHub của bạn:

```sh
gh auth token | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
docker pull ghcr.io/tinnguyen0706/latex-times-new-roman:latest
```

Kiểm tra image và font:

```sh
docker image inspect ghcr.io/tinnguyen0706/latex-times-new-roman:latest
docker run --rm ghcr.io/tinnguyen0706/latex-times-new-roman:latest fc-match "Times New Roman" --format "%{family[0]}\n"
docker run --rm ghcr.io/tinnguyen0706/latex-times-new-roman:latest kpsewhich acmart.cls
```

Lệnh `fc-match` phải trả về `Times New Roman`; lệnh `kpsewhich` phải trả về
đường dẫn đến `acmart.cls`.

Image đã chứa sẵn Times New Roman hợp lệ. Người sử dụng không cần tải font,
không cần giải mã archive font và không cần build lại image.

> Nếu GitHub CLI không có scope `read:packages`, chạy
> `gh auth refresh --hostname github.com --scopes read:packages` rồi đăng nhập
> Docker lại.

## 4. Cài LaTeX Workshop và mở project

Cài extension bằng terminal:

```sh
code --install-extension James-Yu.latex-workshop
code .
```

Trong VS Code:

1. Nhấn `Ctrl+Shift+P` để mở Command Palette.
2. Chạy `Developer: Reload Window`.
3. Mở file `sample/main.tex`.

Workspace đã cấu hình sẵn trong `.vscode/settings.json`:

- LaTeX Workshop dùng image
  `ghcr.io/tinnguyen0706/latex-times-new-roman:latest`;
- recipe mặc định là `XeLaTeX via Docker`;
- output được ghi vào thư mục `build/` cạnh file TeX gốc;
- auto-build bị tắt, nên lưu file không tự chạy container;
- `tex-fmt --nowrap` chạy trên host khi lưu file `.tex`.

## 5. Build và xem PDF bằng VS Code

1. Mở file gốc `sample/main.tex`.
2. Nhấn `Ctrl+Alt+B`, hoặc chạy
   `LaTeX Workshop: Build LaTeX project` trong Command Palette.
3. Chạy `LaTeX Workshop: View LaTeX PDF` để xem PDF.

Kết quả nằm tại:

```text
sample/build/main.pdf
```

Format và build là hai thao tác riêng:

- lưu file: `tex-fmt` chạy trực tiếp trên host;
- nhấn build: LaTeX Workshop khởi động container từ image GHCR;
- source LaTeX hiện tại được mount vào container để tạo PDF.

## 6. Build thủ công không qua VS Code

### Windows (PowerShell)

```powershell
docker run --rm `
  --volume "${PWD}:/workspace" `
  --workdir /workspace/sample `
  ghcr.io/tinnguyen0706/latex-times-new-roman:latest `
  latexmk -xelatex -interaction=nonstopmode -file-line-error `
    -outdir=build main.tex
```

### Linux (Arch-based)

```sh
docker run --rm \
  --volume "$PWD:/workspace" \
  --workdir /workspace/sample \
  ghcr.io/tinnguyen0706/latex-times-new-roman:latest \
  latexmk -xelatex -interaction=nonstopmode -file-line-error \
    -outdir=build main.tex
```

Đối với tài liệu khác, thay `/workspace/sample` bằng thư mục chứa file TeX gốc
và thay `main.tex` bằng tên file tương ứng.

## 7. Viết bài theo layout ACM CHI

Image hỗ trợ hai layout CHI hiện hành bằng XeLaTeX:

- bản nộp review ẩn danh, một cột:

  ```tex
  \documentclass[manuscript,review,anonymous]{acmart}
  ```

- bản xuất bản, hai cột:

  ```tex
  \documentclass[sigconf]{acmart}
  ```

Build giống các tài liệu khác; thay thư mục và tên file bằng project ACM của
bạn:

```sh
docker run --rm \
  --volume "$PWD:/workspace" \
  --workdir /workspace/paper \
  ghcr.io/tinnguyen0706/latex-times-new-roman:latest \
  latexmk -xelatex -interaction=nonstopmode -file-line-error \
    -outdir=build main.tex
```

Bibliography của ACM dùng `ACM-Reference-Format`. Image chỉ cài dependency cần
cho hai layout trên; các option tùy chọn như `authordraft`, `pbalance=true` và
layout `sigchi` cũ không được hỗ trợ.

## 8. Format mã nguồn

VS Code tự chạy formatter khi lưu file `.tex`. Có thể chạy thủ công:

```sh
tex-fmt --nowrap sample/main.tex
```

Chỉ kiểm tra format, không sửa file:

```sh
tex-fmt --check --nowrap sample/main.tex
```

Tắt formatter cho một đoạn đặc biệt:

```tex
% tex-fmt: off
Đoạn này được giữ nguyên.
% tex-fmt: on
```

## 9. Cập nhật source code và image

Lấy source mới nhất:

```sh
git pull --ff-only
```

Lấy image mới nhất:

```sh
docker pull ghcr.io/tinnguyen0706/latex-times-new-roman:latest
```

Sau khi `.vscode/settings.json` thay đổi, chạy lại
`Developer: Reload Window` trong VS Code.

## 10. File build và Git

Các file trung gian như `.aux`, `.log`, `.xdv`, `.toc` và `.synctex.gz` được
Git ignore. PDF trong thư mục `build/` vẫn có thể được commit.

Dọn file trung gian nhưng giữ PDF:

### Windows (PowerShell)

```powershell
docker run --rm `
  --volume "${PWD}:/workspace" `
  --workdir /workspace/sample `
  ghcr.io/tinnguyen0706/latex-times-new-roman:latest `
  latexmk -c -outdir=build main.tex
```

### Linux (Arch-based)

```sh
docker run --rm \
  --volume "$PWD:/workspace" \
  --workdir /workspace/sample \
  ghcr.io/tinnguyen0706/latex-times-new-roman:latest \
  latexmk -c -outdir=build main.tex
```

## 11. Xử lý lỗi thường gặp

### Không clone được repository

Kiểm tra tài khoản và quyền truy cập:

```sh
gh auth status
gh repo view tinnguyen0706/latex
```

### `unauthorized` hoặc `denied` khi pull GHCR

```sh
gh auth refresh --hostname github.com --scopes read:packages
gh auth token | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
docker pull ghcr.io/tinnguyen0706/latex-times-new-roman:latest
```

Tài khoản GitHub cũng phải có quyền đọc package private.

### `permission denied` khi dùng Docker trên Arch Linux

```sh
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

Sau đó đăng xuất và đăng nhập lại.

### `Please set your LaTeX formatter in latex-workshop.formatting.latex`

Mở cả thư mục project bằng `code .`, không chỉ mở riêng file `.tex`. Kiểm tra:

```sh
tex-fmt --version
```

Sau đó chạy `Developer: Reload Window`.

### VS Code không tìm thấy `tex-fmt` trên Windows

Khởi động lại VS Code và kiểm tra `%LOCALAPPDATA%\Programs\tex-fmt` đã nằm trong
biến môi trường `PATH`.

### Build vẫn dùng image cũ

```sh
docker pull ghcr.io/tinnguyen0706/latex-times-new-roman:latest
```

Sau đó chạy lại `Developer: Reload Window` và build lại tài liệu.
