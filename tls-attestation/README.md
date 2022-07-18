# Instructions

## Prerequisites

### kdrfc

To install (needs a working ruby environment):

```shell
gem install kramdown-rfc
```

Add a `sudo` and a space in front of that command if you don't have all the
permissions needed.

### xml2rfc

To install (needs a working python environment):

```shell
pip install xml2rfc
```

### idnits

```
curl -O https://raw.githubusercontent.com/ietf-tools/idnits/main/idnits
chmod +x idnits
mv idnits <somewhere in your PATH>
```

## Build

To build the rendered I-D in HTML, TXT and XML formats:

```shell
make
```

To get rid of the produced files:

```shell
make clean
```

## Submit

To submit the I-D to the IETF datatracker:

* update `docname` in the markdown file to the intended version
* [build](#build)
* change the name of the produced XML file to reflect the intended version
* [post](https://datatracker.ietf.org/submit/) the XML file and follow further
  instructions coming through your email

## Resources

* [Internet-Draft authors resource site](https://authors.ietf.org)
* [Kramdown-RFC (sparse) documentation](https://github.com/cabo/kramdown-rfc#readme)
* [XML2RFC v3 Vocabulary](https://datatracker.ietf.org/doc/html/rfc7991)
