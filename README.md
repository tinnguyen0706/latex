# LaTeX report template

Project sử dụng XeLaTeX và Times New Roman để build tài liệu tiếng Việt.

## Chuẩn bị font

Đặt bốn file Times New Roman hợp lệ vào thư mục `fonts/`:

| File | Kiểu chữ |
| --- | --- |
| `times.ttf` | Regular |
| `timesbd.ttf` | Bold |
| `timesi.ttf` | Italic |
| `timesbi.ttf` | Bold Italic |

Bạn phải có quyền sử dụng và phân phối các file font này. Docker build sẽ dừng
ngay nếu một file không phải font hợp lệ hoặc không thuộc family
`Times New Roman`.

## Build Docker image

```sh
docker build \
  --build-arg USER_ID="$(id -u)" \
  --build-arg GROUP_ID="$(id -g)" \
  -t latex-times-new-roman .
```

Image cung cấp XeLaTeX, `latexmk`, BibTeX và các package cần thiết cho template.
Nó hoạt động như một LaTeX toolchain tổng quát, vì vậy lệnh build được truyền
vào khi chạy container.

## Build tài liệu mẫu

Từ thư mục gốc của repository, chạy:

```sh
docker run --rm \
  --volume "$PWD:/workspace" \
  --workdir /workspace/sample \
  latex-times-new-roman \
  latexmk -xelatex -interaction=nonstopmode -file-line-error \
    -outdir=build main.tex
```

PDF được tạo tại `sample/build/main.pdf`. UID/GID được truyền khi build image
giúp file output thuộc quyền sở hữu của user hiện tại thay vì `root`.

Để xóa các file build trung gian:

```sh
docker run --rm \
  --volume "$PWD:/workspace" \
  --workdir /workspace/sample \
  latex-times-new-roman \
  latexmk -c -outdir=build main.tex
```

Với tài liệu khác, thay `--workdir` và `main.tex` bằng thư mục cùng file TeX
tương ứng.

## Sử dụng với LaTeX Workshop

Workspace đã cấu hình LaTeX Workshop để chạy recipe `XeLaTeX via Docker` bằng
image `latex-times-new-roman:latest`. Sau khi build image:

1. Mở repository bằng VS Code và cài extension LaTeX Workshop.
2. Chạy lệnh `Developer: Reload Window` để extension đọc lại cấu hình.
3. Mở file TeX gốc, ví dụ `sample/main.tex`.
4. Chạy `LaTeX Workshop: Build LaTeX project` hoặc nhấn `Ctrl+Alt+B`.

PDF được ghi vào thư mục `build` cạnh file TeX gốc và có thể mở bằng PDF viewer
của LaTeX Workshop. Docker daemon phải đang chạy và image phải tồn tại trên máy.
