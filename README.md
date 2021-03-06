```
   _       _             
  /_\  ___| |_ _ __ ___  
 //_\\/ __| __| '__/ _ \ 
/  _  \__ \ |_| | | (_) |
\_/ \_/___/\__|_|  \___/ 
```

Astro Generator
===============

## Requirements

- [Git](https://git-scm.com/)
- We recommend you use [nvm](https://github.com/creationix/nvm#installation) to
manage node and npm versions.
- node ^4.0.0 LTS
- npm ^2.0.0

To generate an Astro project:

```sh
bash <(curl -fsS https://raw.githubusercontent.com/mobify/generator-astro/master/generator.sh)
```

Or, if you have the repo checked out:

```sh
./generate.sh
```

Why `generator-astro` and not `astro-generator`
-----------------------------------------------

Initially we envisioned using [Yeoman](http://yeoman.io/) for the generator. Yeoman generators are prefixed with `generator-` and so we followed that convention. 
