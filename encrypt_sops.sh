#!/usr/bin/env bash
#by Gergely Szalay, ATIX AG.
#helper function
usage() { echo "Usage: $0 -i [FILE TO ENCRYPT} -k [ENCRYPTION KEY]"; exit 0; }
#determine arguments: file to encrypt, key, or need for help
while getopts "i:k:h" inputargument;
do
case "${inputargument}" in
i)
INPUTFILE=${OPTARG}
;;
k)
ENCRYPTIONKEY=${OPTARG}
;;
h)
usage
;;
*)
usage
;;
esac
done
#check the arguments
if [ -z ${INPUTFILE} ] || [ -z ${ENCRYPTIONKEY} ]
then usage
exit 1
fi
#handle, if the files are not locally placed
#you could put path and file into two seperate variables, but now we will use them only once.
#INPUTDIR=$(dirname ${INPUTFILE})
#INPUTFILENAME=$(basename ${INPUTFILE})
#in this case you go for more variables, you might need to change to this defintion instead of the uncommented one
#OUTPUTFILE=${INPUTDIR})/enc_${INPUTFILENAME}
OUTPUTFILE=$(dirname ${INPUTFILE})/enc_$(basename ${INPUTFILE})
echo "The new file will be ${OUTPUTFILE}"
#Do the magic, assuming, that the file does exist
sops -a ${ENCRYPTIONKEY} -e ${INPUTFILE} > ${OUTPUTFILE}
#check for errors, remove false OUTPUTFILE
if [ $? -eq 0 ]
then
echo "${OUTPUTFILE} has been created, you can use it for git & Co."
else
echo -e "\nSomething went wrong, please check the message above\n${OUTPUTFILE} will be removed\n"
rm ${OUTPUTFILE}
fi
