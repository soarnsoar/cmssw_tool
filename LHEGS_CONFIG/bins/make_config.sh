#!/bin/bash


####INPUT OPTIONS#####
function  usage {
   echo "USAGE: $0 param..";
   echo "-n : number of events";
   echo "-g : gridpack location";
   echo "-f : fragment file name";
   echo "-t : name tag of python output"
   exit 0;
}

PARAM="n:g:f:t:h";
###Get options###
while getopts $PARAM opt; do
    case $opt in
	n)
            OPT_N=$OPTARG;
            ;;
	g)
            OPT_G=$OPTARG;
            ;;
	f)
	    OPT_F=$OPTARG;
            ;;
	t)
            OPT_NAME=$OPTARG;
	    ;;
	h)
            usage;
            ;;
    esac
done

if [ -z $OPT_N ]; then
    echo "@@No -n option : number of events"
    exit 0
fi

if [ -z $OPT_G ]; then
    echo "@@No -g option : gridpack location"
    exit 0
fi

if [ -z $OPT_F ]; then
    echo "@@No -f option : fragment name"
    exit 0
fi

if [ -z $OPT_NAME ]; then
    echo "@@No -t option : name tag"
    exit 0
fi
##############################################

### settings to modify
# number of events per job 
NEVTS=$OPT_N
GRIDPACK=$OPT_G
GENFRAGMENT=$OPT_F
NAMETAG=$OPT_NAME

# path to submit jobs 
WORKDIR=`pwd -P`
# path for private fragments not yet in cmssw
FRAGMENTDIR=${WORKDIR}
echo "##FRAGMENTDIR=$FRAGMENTDIR ##"
# release setup 
#
export SCRAM_ARCH=slc6_amd64_gcc630
#SCRAM_ARCH=slc6_amd64_gcc481
RELEASE=CMSSW_9_3_8



### done with settings 


### setup release 
if [ -r ${WORKDIR}/${RELEASE}/src ] ; then 
    echo release ${RELEASE} already exists
else
    echo "@@scram p@@"
    scram p CMSSW ${RELEASE}
fi


cd ${WORKDIR}/${RELEASE}/src

eval `scram runtime -sh`

#cmsenv

### checkout generator configs 
while [ ! -r ${CMSSW_BASE}/src/Configuration/Generator/ ] ; do
    
    echo "@@addpkg@@ PWD="$PWD
#    git-cms-addpkg Configuration/Generator
   # git cms-addpkg --quiet Configuration/Generator
    git cms-addpkg Configuration/Generator
    
done
### copy additional fragments if needed 
if [ -d "${FRAGMENTDIR}" ]; then 
    cp ${FRAGMENTDIR}/*.py ${CMSSW_BASE}/src/Configuration/Generator/python/. 
fi


### scram release 
scram b 


### start tag loop for setups to be validated  

    ### move to python path 
cd ${CMSSW_BASE}/src/Configuration/Generator/python/
    
    ### check that fragments are available 
echo "Check that fragments are available ..."
if [ ! -s ${GENFRAGMENT} ] ; then 
    echo "... cannot find ${GENFRAGMENT}"
    exit 0;
else
    echo "... found required fragments!"
fi

    ### create generator fragment 
CONFIG=${OTAG}_cff.py
if [ -f ${CONFIG} ] ; then 
    rm ${CONFIG} 
fi

cat > ${CONFIG} <<EOF
from datetime import datetime
dt = datetime.now()
import FWCore.ParameterSet.Config as cms
externalLHEProducer = cms.EDProducer('ExternalLHEProducer', 
args = cms.vstring('${GRIDPACK}'),
nEvents = cms.untracked.uint32(5000),
numberOfParameters = cms.uint32(1),  
outputFile = cms.string('cmsgrid_final.lhe'),
scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh')
)
EOF
cat ${GENFRAGMENT} >> ${CONFIG}
    
       
    ### make validation fragment 
echo "make validation fragment" 
cmsDriver.py Configuration/Generator/python/${CONFIG} \
    -n ${NEVTS} --mc --no_exec --python_filename cmsrun_${NAMETAG}.py \
    -s LHE,GEN --datatier LHE,GEN --eventcontent LHE,RAWSIM \
    --conditions auto:run2_mc_FULL --beamspot Realistic8TeVCollision 

echo "move to submission directory"
    ### move to submission directory 
cd ${WORKDIR}


    ### prepare submission script 



cp ${CMSSW_BASE}/src/Configuration/Generator/python/cmsrun_${NAMETAG}.py . 
### adjust random numbers 
#LINE=`egrep -n Configuration.StandardSequences.Services_cff cmsrun_${OTAG}.py | cut -d: -f1 `
#   # SEED=`echo "5267+${OFFSET}" | bc`
#sed -i "${LINE}"aprocess.RandomNumberGeneratorService.generator.initialSeed=seed cmsrun_${NAMETAG}.py  
#    #SEED=`echo "289634+\${OFFSET}" | bc`
#sed -i "${LINE}"aprocess.RandomNumberGeneratorService.externalLHEProducer.initialSeed=seed cmsrun_${NAMETAG}.py  









