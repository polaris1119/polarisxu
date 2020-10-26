# 在 iOS 和 Android 上运行 Go 代码

在本教程中，我们将构建一个简单的 Go 包，您可以从 iOS 应用程序（Swift）和 Android 应用程序（Kotlin）运行该软件包。

本教程不会使用[go mobile](https://github.com/golang/mobile) 框架。相反，它使用 Cgo 构建可导入到您的移动项目中的原始静态（iOS）和共享（Android） C 库（Go Mobile 框架在后台进行此操作）。

## 构建

在本教程中，我们将创建具有以下结构的简单 monorepo：

```bash
.
├── android/
├── go/
│   ├── cmd/
│   │   └── libfoo/
│   │       └── main.go
│   ├── foo/
│   │   └── foo.go
│   ├── go.mod
│   └── go.sum
└── ios/
$ mkdir -p android ios go/cmd/libfoo go/foo
```

我们将从 Go 代码开始，稍后再返回创建 iOS 和 Android 项目。

```zsh
$ cd go
$ go mod init rogchap.com/libfoo
```

## Foo 包

```go
// go/foo/foo.go
package foo

// Reverse reverses the given string by each utf8 character
func Reverse(in string) string {
    n := 0
    rune := make([]rune, len(in))
    for _, r := range in {
        rune[n] = r
        n++
    }
    rune = rune[0:n]
    for i := 0; i < n/2; i++ {
        rune[i], rune[n-1-i] = rune[n-1-i], rune[i]
    }
    return string(rune)
}
```

我们的`foo`程序包有一个函数`Reverse`，该函数具有单个字符串参数`in`和单个字符串输出。

## 导出为 C

为了使我们的 C 库调用我们的`foo`包，我们需要导出所有要公开给 C 的函数，并带有特殊`export`注释。该包装器必须位于`main`包装中：

```go
// go/cmd/libfoo/main.go
pacakge main

import "C"

// other imports should be seperate from the special Cgo import
import (
    "rogchap.com/libfoo/foo"
)

//export reverse
func reverse(in *C.char) *C.char {
    return C.CString(foo.Reverse(C.GoString(in)))
}

func main() {}
```

我们正在使用特殊的 `C.GoString()`和`C.CString()`函数在 Go 字符串和 C 字符串之间进行转换。

*注意：*我们要导出的函数不必是导出的 Go 函数（即以大写字母开头）。还要注意是空`main`函数；这对于 Go 代码进行编译是必需的，否则会出现 `function main is undeclared in the main package`错误。

让我们通过使用 `-buildmode` 标志创建一个静态 C 库来测试我们的构建：

```
go build -buildmode=c-archive -o foo.a ./cmd/libfoo
```

这应该已经输出了 C 库：`foo.a`和头文件：`foo.h`。您应该在头文件的底部看到导出的函数：

```C
extern char* reverse(char* in);
```

## 为 iOS 构建

我们的目标是创建一个可以在 iOS 设备和 iOS 模拟器上使用的 [Fat 二进制文件](https://en.wikipedia.org/wiki/Fat_binary)。

Go 标准库包含用于构建 iOS 的脚本： [`$GOROOT/misc/ios/clangwrap.sh`](https://golang.org/misc/ios/clangwrap.sh)，但是该脚本仅针对生成`arm64`，而`x86_64`iOS Simulator 也需要该脚本 。因此，我们将创建自己的`clangwrap.sh`：

```sh
#!/bin/sh

# go/clangwrap.sh

SDK_PATH=`xcrun --sdk $SDK --show-sdk-path`
CLANG=`xcrun --sdk $SDK --find clang`

if [ "$GOARCH" == "amd64" ]; then
    CARCH="x86_64"
elif [ "$GOARCH" == "arm64" ]; then
    CARCH="arm64"
fi

exec $CLANG -arch $CARCH -isysroot $SDK_PATH -mios-version-min=10.0 "$@"
```

不要忘记让它可执行：

```
chmod +x clangwrap.sh
```

现在，我们可以为每种体系结构构建库，并使用该`lipo`工具（通过 Makefile）合并为 Fat 二进制文件：

```makefile
# go/Makefile

ios-arm64:
	CGO_ENABLED=1 \
	GOOS=darwin \
	GOARCH=arm64 \
	SDK=iphoneos \
	CC=$(PWD)/clangwrap.sh \
	CGO_CFLAGS="-fembed-bitcode" \
	go build -buildmode=c-archive -tags ios -o $(IOS_OUT)/arm64.a ./cmd/libfoo

ios-x86_64:
	CGO_ENABLED=1 \
	GOOS=darwin \
	GOARCH=amd64 \
	SDK=iphonesimulator \
	CC=$(PWD)/clangwrap.sh \
	go build -buildmode=c-archive -tags ios -o $(IOS_OUT)/x86_64.a ./cmd/libfoo

ios: ios-arm64 ios-x86_64
	lipo $(IOS_OUT)/x86_64.a $(IOS_OUT)/arm64.a -create -output $(IOS_OUT)/foo.a
	cp $(IOS_OUT)/arm64.h $(IOS_OUT)/foo.h
```

## 创建我们的 iOS 应用程序

使用 XCode，我们可以创建一个简单的单页应用程序。我将使用 Swift UI，但这与 UIKit 一样容易：

```swift
// ios/foobar/ContentView.swift

struct ContentView: View {

    @State private var txt: String = ""

    var body: some View {
        VStack{
            TextField("", text: $txt)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Reverse"){
                // Reverse text here
            }
            Spacer()
        }
        .padding(.all, 15)
    }
}
```

在 Xcode 中，将新生成的`foo.a` 和 `foo.h` 拖进我们的项目。为了使我们的 Swift 代码与我们的库互操作，我们需要创建一个桥接头文件：

```c
// ios/foobar/foobar-Bridging-Header.h

#import "foo.h"
```

在 Xcode `Build Settings` 中，`Swift Compiler - General` 下，设置 `Objective-C Bridging Header` 为我们刚刚创建的文件：`foobar/foobar-Bridging-Header.h`。

我们还需要设置 `Library Search Paths` 为包括我们生成的头文件 `foo.h` 的目录。（当您将文件拖放到项目中时，Xcode 可能已经为您完成了此操作）。

现在我们可以从 Swift 调用函数，然后构建并运行：

```swift
// ios/foobar/ContentView.swift

Button("Reverse"){
    let str = reverse(UnsafeMutablePointer<Int8>(mutating: (self.txt as NSString).utf8String))
    self.txt = String.init(cString: str!, encoding: .utf8)!
    // don't forget to release the memory to the C String
    str?.deallocate()
}
```

![libfoo ios应用程序](https://rogchap.com/posts/img/libfoo_ios.gif)

## 创建 Android 应用程序

使用 Android Studio，我们将创建一个新的 Android 项目。从 Project Templates 中选择 `Native C++`，这将创建一个带有 Empty Activity 的项目，该项目被配置为使用 Java Native Interface（JNI）。我们仍将选择 `Kotlin` 作为该项目的语言。

创建一个简单的 Activity 后，加上 `EditText` 和，`Button` 两个控件，为应用创建基本功能：

```kotlin
// android/app/src/main/java/com/rogchap/foobar/MainActivity.kt

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        btn.setOnClickListener {
            txt.setText(reverse(txt.text.toString()))
        }
    }

    /**
     * A native method that is implemented by the 'native-lib' native library,
     * which is packaged with this application.
     */
    private external fun reverse(str: String): String

    companion object {
        // Used to load the 'native-lib' library on application startup.
        init {
            System.loadLibrary("native-lib")
        }
    }
}
```

我们创建了（并调用）一个外部函数 `reverse`，我们需要在 JNI （C++）实现：

```cpp
// android/app/src/main/cpp/native-lib.cpp

extern "C" {
    jstring
    Java_com_rogchap_foobar_MainActivity_reverse(JNIEnv* env, jobject, jstring str) {
        // Reverse text here
        return str;
    }
}
```

JNI 代码必须遵循约定才能在本机 C++ 和 Kotlin（JVM）之间互操作。

## 为 Android 构建

在许多版本的 Android 和 NDK 中，JNI 与外部库的工作方式已发生变化。当前（也是最简单的方法）是将输出的库放置到一个特殊的 `jniLibs` 文件夹中，该文件夹将复制到我们的最终 APK 文件中。

与创建 Fat 二进制文件（就像我们在 iOS 中所做的那样）不同，我将每个体系结构放置在正确的文件夹中。同样，对于 JNI，约定很重要。

```makefile
// go/Makefile

ANDROID_OUT=../android/app/src/main/jniLibs
ANDROID_SDK=$(HOME)/Library/Android/sdk
NDK_BIN=$(ANDROID_SDK)/ndk/21.0.6113669/toolchains/llvm/prebuilt/darwin-x86_64/bin

android-armv7a:
	CGO_ENABLED=1 \
	GOOS=android \
	GOARCH=arm \
	GOARM=7 \
	CC=$(NDK_BIN)/armv7a-linux-androideabi21-clang \
	go build -buildmode=c-shared -o $(ANDROID_OUT)/armeabi-v7a/libfoo.so ./cmd/libfoo

android-arm64:
	CGO_ENABLED=1 \
	GOOS=android \
	GOARCH=arm64 \
	CC=$(NDK_BIN)/aarch64-linux-android21-clang \
	go build -buildmode=c-shared -o $(ANDROID_OUT)/arm64-v8a/libfoo.so ./cmd/libfoo

android-x86:
	CGO_ENABLED=1 \
	GOOS=android \
	GOARCH=386 \
	CC=$(NDK_BIN)/i686-linux-android21-clang \
	go build -buildmode=c-shared -o $(ANDROID_OUT)/x86/libfoo.so ./cmd/libfoo

android-x86_64:
	CGO_ENABLED=1 \
	GOOS=android \
	GOARCH=amd64 \
	CC=$(NDK_BIN)/x86_64-linux-android21-clang \
	go build -buildmode=c-shared -o $(ANDROID_OUT)/x86_64/libfoo.so ./cmd/libfoo

android: android-armv7a android-arm64 android-x86 android-x86_64
```

**注意**确保为您的 Android SDK 和已下载的 NDK 版本设置正确的位置。

`make android` 将我们需要的所有共享库构建到正确的文件夹中。现在，我们需要将库添加到 CMake：

```cmake
// android/app/src/main/cpp/CMakeLists.txt

// ...

add_library(lib_foo SHARED IMPORTED)
set_property(TARGET lib_foo PROPERTY IMPORTED_NO_SONAME 1)
set_target_properties(lib_foo PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${CMAKE_ANDROID_ARCH_ABI}/libfoo.so)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${CMAKE_ANDROID_ARCH_ABI}/)

// ...

target_link_libraries(native-lib lib_foo ${log-lib})
```

我花了一段时间才弄清楚这些设置，再次命名很重要，因此使用库命名 `lib_xxxx` 并设置属性很重要，同时设置 `IMPORTED_NO_SONAME 1`，否则您的 apk 会在错误的位置查找你的库。

现在，我们可以将 JN I 代码连接到 Go 库中，然后运行我们的应用程序：

```cpp
// android/app/src/main/cpp/native-lib.cpp

#include "libfoo.h"

extern "C" {
    jstring
    Java_com_rogchap_foobar_MainActivity_reverse(JNIEnv* env, jobject, jstring str) {
        const char* cstr = env->GetStringUTFChars(str, 0);
        char* cout = reverse(const_cast<char*>(cstr));
        jstring out = env->NewStringUTF(cout);
        env->ReleaseStringUTFChars(str, cstr);
        free(cout);
        return out;
    }
}
```

![libfoo android应用](https://rogchap.com/posts/img/libfoo_android.gif)

## 结论

Go 的优势之一就是它是跨平台的，这不仅意味着 Window，Mac 和 Linux，Go 还可以针对许多其他体系结构，包括 iOS 和 Android。现在，您可以在工具栏中找到另一个选项，以创建在服务器、移动应用程序甚至 Web（通过 Web 程序集）上运行的共享库。

本教程的所有代码均可在 GitHub 上获得：<https://github.com/rogchap/libfoo>

期待听到您使用 Go 构建的新杀手级应用程序。

> 原文链接：https://rogchap.com/2020/09/14/running-go-code-on-ios-and-android/
>
> 作者：Roger Chapman
>
> 译者：polarisxu
