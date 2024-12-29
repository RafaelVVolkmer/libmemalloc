<a id="readme-top"></a>

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

<div align="center">
  
  [![Contributors][contributors-shield]][contributors-url]
  [![Forks][forks-shield]][forks-url]
  [![Stargazers][stars-shield]][stars-url]
  [![Issues][issues-shield]][issues-url]
  [![ULicense][license-shield]][license-url]
  [![LinkedIn][linkedin-shield]][linkedin-url]
  
</div>

###

<p align="center">
  <img src="readme/libmemalloc_logo.svg" alt="FROST Logo" width="30%"/>
</p>

##

<div align="center">
  by: Rafael V. Volkmer - @RafaelVVolkmer - rafael.v.volkmer@gmail.com
</div>

##

### - Project Description

This library is responsible for implementing a customized dynamic memory allocation system, with a choice between different algorithms and usage strategies — First-Fit, Next-Fit, Best-Fit. It implements a memory alignment system by processor architecture, direct access to the heap memory space through the linking process and, above all, a memory detection system, where every allocation is mapped with its name, size, address in the heap, line, file and function where they were allocated and free flag, being able to access this information and print it on the terminal at any time, during program execution time.

##

## - Repository tree

```python
/my-alloc
├── /inc
│   └── libmemalloc.h
├── /src
│   └── libmemalloc.c
├── /bin
│   ├── libmemalloc.o
│   ├── libmemalloc.a
│   └── libmemalloc.so
├── .gitattributes
├── .gitignore
├── LICENSE
├── README.md
└── makefile
```

# References
[The Garbage Collection Handbook: The art of automatic memory management](https://gchandbook.org)
