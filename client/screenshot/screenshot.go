package screenshot

// screenshot package
// just didn't want to have dependencies, so reimplemented this pkg
// here are some screenshot packages:
// 	https://github.com/kbinani/screenshot
// 	https://github.com/vova616/screenshot

// and some sources:
// 	https://stackoverflow.com/questions/3291167/how-can-i-take-a-screenshot-in-a-windows-application
// 	https://docs.microsoft.com/uk-ua/windows/win32/gdi/capturing-an-image?redirectedfrom=MSDN

import (
	"errors"
	"fmt"
	"image"
	"image/png"
	"log"
	"os"
	"syscall"
	"unsafe"
)

func Test() {
	fmt.Println("test")
}

var (
	user32                     = syscall.NewLazyDLL("user32.dll")
	gdi32                      = syscall.NewLazyDLL("gdi32.dll")
	kernel32                   = syscall.NewLazyDLL("kernel32.dll")
	procGetDC                  = user32.NewProc("GetDC")
	procReleaseDC              = user32.NewProc("ReleaseDC")
	procGlobalAlloc            = kernel32.NewProc("GlobalAlloc")
	procGlobalFree             = kernel32.NewProc("GlobalFree")
	procGlobalLock             = kernel32.NewProc("GlobalLock")
	procGlobalUnlock           = kernel32.NewProc("GlobalUnlock")
	procGetDeviceCaps          = gdi32.NewProc("GetDeviceCaps")
	procCreateCompatibleDC     = gdi32.NewProc("CreateCompatibleDC")
	procCreateCompatibleBitmap = gdi32.NewProc("CreateCompatibleBitmap")
	procSelectObject           = gdi32.NewProc("SelectObject")
	procBitBlt                 = gdi32.NewProc("BitBlt")
	procGetDIBits              = gdi32.NewProc("GetDIBits")
	procDeleteDC               = gdi32.NewProc("DeleteDC")
	procDeleteObject           = gdi32.NewProc("DeleteObject")
	// procCreateDIBSection       = gdi32.NewProc("CreateDIBSection")
)

const (
	SRCCOPY        = 0x00CC0020
	GMEM_MOVEABLE  = 0x0002
	BI_RGB         = 0x0000
	GHND           = 0x0042
	DIB_RGB_COLORS = 0x00
	DESKTOPVERTRES = 117
	DESKTOPHORZRES = 118
)

type BITMAPINFOHEADER struct {
	BiSize          uint32
	BiWidth         int32
	BiHeight        int32
	BiPlanes        uint16
	BiBitCount      uint16
	BiCompression   uint32
	BiSizeImage     uint32
	BiXPelsPerMeter int32
	BiYPelsPerMeter int32
	BiClrUsed       uint32
	BiClrImportant  uint32
}

type RGBQUAD struct {
	RgbBlue     byte
	RgbGreen    byte
	RgbRed      byte
	RgbReserved byte
}

type BITMAPINFO struct {
	BmiHeader BITMAPINFOHEADER
	BmiColors *RGBQUAD
}

func Capture(x, y, width, height int32) (image.Image, error) {
	hwnd := 0

	// hwnd = 0, therefore retrieve DC for the entire screen
	hdc, _, err := procGetDC.Call(uintptr(hwnd))
	if !errOk(err) {
		return nil, errors.New("proc GetDC failed")
	}
	defer procReleaseDC.Call(uintptr(hwnd), hdc)

	// in-memory device context
	mdc, _, err := procCreateCompatibleDC.Call(hdc)
	if !errOk(err) {
		return nil, errors.New("proc CreateCompatibleDC failed")
	}
	defer procDeleteDC.Call(mdc)

	bitmap, _, err := procCreateCompatibleBitmap.Call(hdc, uintptr(width), uintptr(height))
	if !errOk(err) {
		return nil, errors.New("proc CreateCompatibleBitmat failed")
	}
	defer procDeleteObject.Call(bitmap)

	header := createBitmapInfoHeader(width, height)
	bitmapSize := ((int64(width)*int64(header.BiBitCount) + 31) / 32) * 4 * int64(height)

	hDIB, _, err := procGlobalAlloc.Call(GMEM_MOVEABLE, uintptr(bitmapSize))
	if !errOk(err) {
		return nil, errors.New("proc GlobalAlloc failed")
	}
	defer procGlobalFree.Call(hDIB)

	lpbitmap, _, err := procGlobalLock.Call(hDIB)
	if !errOk(err) {
		return nil, errors.New("proc GlobalLock failed")
	}
	defer procGlobalUnlock.Call(hDIB)

	// alternative to compatible bitmap + alloc and lock
	// ptr := unsafe.Pointer(uintptr(0))
	// bitmap, _, err = procCreateDIBSection.Call(hdc, uintptr(unsafe.Pointer(&header)), win.DIB_RGB_COLORS, uintptr(unsafe.Pointer(&ptr)), 0, 0)
	// check(err)

	old, _, err := procSelectObject.Call(mdc, bitmap)
	if !errOk(err) {
		return nil, errors.New("proc SelectObject failed")
	}
	defer procSelectObject.Call(mdc, old)

	_, _, err = procBitBlt.Call(mdc, 0, 0, uintptr(int32(width)), uintptr(int32(height)), hdc, 0, 0, SRCCOPY)
	if !errOk(err) {
		return nil, errors.New("proc BitBlt failed")
	}

	_, _, err = procGetDIBits.Call(
		uintptr(hdc),
		uintptr(bitmap),
		uintptr(0),
		uintptr(height),
		uintptr(lpbitmap),
		uintptr(unsafe.Pointer((*BITMAPINFO)(unsafe.Pointer(&header)))),
		uintptr(DIB_RGB_COLORS),
		0,
		0)
	if !errOk(err) {
		return nil, errors.New("proc GetDIBits failed")
	}

	img := image.NewRGBA(image.Rect(0, 0, int(width), int(height)))

	for i := 0; i < int(width*height); i++ {
		offset := 4 * i
		base := lpbitmap + uintptr(offset)

		r := *(*uint8)(unsafe.Pointer(base + 2))
		g := *(*uint8)(unsafe.Pointer(base + 1))
		b := *(*uint8)(unsafe.Pointer(base))

		img.Pix[offset], img.Pix[offset+1], img.Pix[offset+2], img.Pix[offset+3] = r, g, b, 255
	}

	return img, nil
}

func CaptureScreen() (image.Image, error) {
	dc, _, _ := procGetDC.Call(0)

	width := getWidth(dc)
	height := getHeight(dc)

	img, err := Capture(0, 0, int32(width), int32(height))
	if err != nil {
		// log.Fatal(err.Error())
		return nil, err
	}

	return img, err

	// println("ok")
	// os.Remove("test.png")

	// file, _ := os.Create("test.png")
	// defer file.Close()
	// png.Encode(file, img)
}

func test() {
	dc, _, _ := procGetDC.Call(0)

	width := getWidth(dc)
	height := getHeight(dc)

	img, err := Capture(0, 0, int32(width), int32(height))
	if err != nil {
		log.Fatal(err.Error())
	}

	println("ok")
	os.Remove("test.png")

	file, _ := os.Create("test.png")
	defer file.Close()
	png.Encode(file, img)
}

func GetDeviceCaps(hdc uintptr, index int) int {
	ret, _, _ := procGetDeviceCaps.Call(
		uintptr(hdc),
		uintptr(index))

	return int(ret)
}

func getWidth(dc uintptr) int {
	return GetDeviceCaps(dc, DESKTOPHORZRES)
}

func getHeight(dc uintptr) int {
	return GetDeviceCaps(dc, DESKTOPVERTRES)
}

func createBitmapInfoHeader(width, height int32) BITMAPINFOHEADER {
	header := BITMAPINFOHEADER{}
	header.BiSize = uint32(unsafe.Sizeof(header))
	header.BiPlanes = 1
	header.BiBitCount = 32
	header.BiWidth = int32(width)
	header.BiHeight = int32(-height)
	header.BiCompression = BI_RGB
	header.BiSizeImage = 0

	return header
}

func errOk(err error) bool {
	return err == nil || err.Error() == "The operation completed successfully."
}
