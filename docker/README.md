### Docker Images Glossary

**pcf-tools** - This image contains the following tools:
  - bosh
  - cf
  - uaac
  - pivnet
  - om
  - mc
  - fly
  - credhub cli
  - kubectl
  - pks
  - bbr
  - curl
  - jq
  - git
  - openssl
  - wget
  - nc

A Dockerfile for this image can be found [HERE](https://gitlower.onefiserv.net/PCF/pcf-docker-tools/blob/master/pcf-tools/Dockerfile) in this repo, as well as a handy ```docker-helper``` script. Should the binaries need to be updated, simply clone this repo, replace the links to the binary downloads, and run the script located in the the ```pcf-tools``` directory. It will build the image, tag it for each foundation's docker registry and push it there.
