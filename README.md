<a id="readme-top"></a>

<div align="center">
  
  [![Contributors][contributors-shield]][contributors-url]
  [![Forks][forks-shield]][forks-url]
  [![Stargazers][stars-shield]][stars-url]
  [![Issues][issues-shield]][issues-url]
  [![ULicense][license-shield]][license-url]
  [![LinkedIn][linkedin-shield]][linkedin-url]
  
</div>

##

<p align="center">
  <img src="readme/libmemalloc.svg" alt="libmemalloc logo" width="100%"/>
</p>

##

<div align="center">
  by: Rafael V. Volkmer - @RafaelVVolkmer - rafael.v.volkmer@gmail.com
</div>

##

# - Project Description

This library is responsible for implementing a customized dynamic memory allocation system, with a choice between different algorithms and usage strategies — First-Fit, Next-Fit, Best-Fit. It implements a memory alignment system by processor architecture, direct access to the heap memory space through the linking process and, above all, a memory detection system, where every allocation is mapped with its name, size, address in the heap, line, file and function where they were allocated and free flag, being able to access this information and print it on the terminal at any time, during program execution time.

**`v2.0.00.00`**

libmemalloc now features native implementations of memcpy and memset, as well as support for dynamically expanding the heap via brk and sbrk algorithms. A built-in garbage collector is also provided, which you can invoke at your discretion. For improved performance, you might consider running the garbage collector periodically in a dedicated thread; however, this option was not included by default to avoid imposing invasive changes on your application.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

# - Repository tree

```python
/libmemalloc
├── /inc
│   ├── logs.h
│   └── libmemalloc.h
├── /src
│   └── libmemalloc.c
├── /bin
│   ├── libmemalloc.o
│   ├── libmemalloc.a
│   └── libmemalloc.so
├── /readme
│    └── libmemalloc.svg
├── dockerfile
├── CMakeLists.txt
├── .gitattributes
├── .gitignore
├── LICENSE
└── README.md
```

The libmemalloc repository is structured to separate different aspects of the project clearly:

- **Source Code Organization:**
The src and inc directories segregate implementation files from interface declarations, promoting modularity and ease of maintenance.

- **Build Outputs:**
The bin directory holds the compiled binaries, keeping them separate from the source code and preventing clutter in the main project directories.

- **Documentation and Assets:**
The readme directory contains visual assets that support the project's documentation, enhancing the clarity and professionalism of the project presentation.

- **Configuration and Metadata:**
Files like .gitignore, .gitattributes, LICENSE, and README.md provide essential information for version control, project licensing, and user guidance, ensuring that the project is well-documented and properly managed.

- **Build Automation:**
The CMake facilitates an automated and consistent build process, which is crucial for collaboration, continuous integration, and efficient development workflows.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

# - Tech Stack and Environment Settings

| **Category**               | **Technologies and Tools**                                                                                                                                                                                                                                  |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Programming Languages**  | ![C](https://img.shields.io/badge/c-%2300599C.svg?style=for-the-badge&logo=c&logoColor=white)                                                                                                                                                                |
| **Build System**           | ![CMake](https://img.shields.io/badge/CMake-%23008FBA.svg?style=for-the-badge&logo=cmake&logoColor=white)                                                                                                                                                      |
| **Version Control**        | ![Git](https://img.shields.io/badge/git-%23F05033.svg?style=for-the-badge&logo=git&logoColor=white) ![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)                                            |
| **Documentation**          | ![Doxygen](https://img.shields.io/badge/doxygen-2C4AA8?style=for-the-badge&logo=doxygen&logoColor=white) ![Markdown](https://img.shields.io/badge/markdown-%23000000.svg?style=for-the-badge&logo=markdown&logoColor=white)                                       |
| **Support Tools**          | ![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)                                                                                                                                                    |
| **Operating System**       | ![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)                                                                                                                                                           |
| **IDE**                    | ![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)                                                                                                                                                     |

<p align="right">(<a href="#readme-top">Back to Top</a>)</p>

---

# - Build and Use

### 1. Cloning the Repository

Open your terminal and run:

```bash
git clone https://github.com/RafaelVVolkmer/libmemalloc.git
cd libmemalloc
```

### 2. Building with CMake

The project uses CMake to configure the build.

**`For Debug Build:`**

```bash
mkdir build-debug
cd build-debug
cmake -DCMAKE_BUILD_TYPE=Debug ..
make
```

**`For Release Build:`**

```bash
mkdir build-release
cd build-release
cmake -DCMAKE_BUILD_TYPE=Release ..
make
```

After building, the generated static libraries (.a), object files (.o), and shared libraries (.so) will be located in your respective build directory.

### 3. Building with Docker

A Dockerfile is provided that uses Alpine Linux as the base image in a multi-stage build. It installs build tools (cmake, make, gcc, etc.), builds the project, and then creates a final minimal image containing only the build artifacts.

**`Build the Docker Image:`**
  
In the repository root, run:

```bash
docker build -t libmemalloc-build .
```

**`Extract the Build Artifacts:`**
  
Assuming the Dockerfile copies the final artifacts into a directory (for example, /usr/local/libmemalloc), you can extract them with:

```bash
docker create --name extract libmemalloc-build
docker cp extract:/usr/local/libmemalloc ./bin
docker rm extract
```

Note: Adjust the path /usr/local/libmemalloc to match the directory specified in your Dockerfile.

### 4. Additional Recommendations

- Multi-stage Build: The Dockerfile leverages multi-stage builds to keep the final image minimal by removing build tools.
- Caching: Organize your Dockerfile so that dependencies are installed first, improving layer caching.
- Non-root User: For security, consider configuring the final image to run as a non-root user.
- Extra Compiler Flags: You may also pass additional optimization flags (e.g., -O3, -march=native) via CMake if needed.
- Testing: It is recommended to add a stage that runs tests so that the final artifacts are only produced if tests pass.

<p align="right">(<a href="#readme-top">Back to Top</a>)</p>

---

# - References

| Title                                                                   | Author / Year                  |
| ------------------------------------------------------------------------ | ---------------------------- |
| **Understanding and Using C Pointers: Core Techniques for Memory Management** | by: Richard M. Reese, 2013  |
| **The Garbage Collection Handbook: The art of automatic memory management**    | by: Anthony Hosking, 2011   |
| **C++ pointers and dynamic memory management**                           | by: Michael C. Daconta, 1993 |
| **Efficient memory programming**                                        | by: David Loshin, 1999       |
| **Memory Management**                                                   | by: Bill Blunden, 2002       |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

[stars-shield]: https://img.shields.io/github/stars/RafaelVVolkmer/libmemalloc.svg?style=flat-square
[stars-url]: https://github.com/RafaelVVolkmer/libmemalloc/stargazers
[contributors-shield]: https://img.shields.io/github/contributors/RafaelVVolkmer/libmemalloc.svg?style=flat-square
[contributors-url]: https://github.com/RafaelVVolkmer/libmemalloc/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/RafaelVVolkmer/libmemalloc.svg?style=flat-square
[forks-url]: https://github.com/RafaelVVolkmer/libmemalloc/network/members
[issues-shield]: https://img.shields.io/github/issues/RafaelVVolkmer/libmemalloc.svg?style=flat-square
[issues-url]: https://github.com/RafaelVVolkmer/libmemalloc/issues
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=flat-square&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/rafaelvvolkmer
[license-shield]: https://img.shields.io/github/license/RafaelVVolkmer/libmemalloc.svg?style=flat-square
[license-url]: https://github.com/RafaelVVolkmer/libmemalloc/blob/main/LICENSE.txt
