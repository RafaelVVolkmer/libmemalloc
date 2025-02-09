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

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

# - Repository tree

```python
/libmemalloc
├── /inc
│   └── libmemalloc.h
├── /src
│   └── libmemalloc.c
├── /bin
│   ├── libmemalloc.o
│   ├── libmemalloc.a
│   └── libmemalloc.so
├── /readme
│    └── libmemalloc.svg
├── .gitattributes
├── .gitignore
├── LICENSE
├── README.md
└── makefile
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
The makefile facilitates an automated and consistent build process, which is crucial for collaboration, continuous integration, and efficient development workflows.

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
