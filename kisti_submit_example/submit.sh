##NEED these tools & setup
#  git@github.com:soarnsoar/submission_scripts.git

NEVENT=5000
NJOBS=1


CURDIR=`pwd`


##(0)GRIDPACK LOCATION
GRIDPACKDIR="/cms/ldap_home/jhchoi/gridvalidation/slow261/gridpacks/"
#GRIDPACKS=($(ls $GRIDPACKDIR/gridpacks/*.tar.xz))
GRIDPACKS=($(ls $GRIDPACKDIR/dyellell012j_5f_LO_MLM_mg261_true_pdfwgt_13_6000_500_1.0_slc6_amd64_gcc630_CMSSW_9_3_8_tarball.tar.xz))
#dyellell012j_5f_LO_MLM_mg261_true_pdfwgt_11_4000_500_1.0_slc6_amd64_gcc630_CMSSW_9_3_8_tarball.tar.xz


##(1) make python configuration
mkdir -p JOBS/
cd $CURDIR/JOBS/
#wget https://raw.githubusercontent.com/cms-sw/genproductions/master/python/ThirteenTeV/Hadronizer/Hadronizer_TuneCP5_13TeV_MLM_5f_max2j_LHE_pythia8_cff.py
echo "@@copy hadronizer@@"
cp ${CURDIR}/Hadronizer_TuneCP5_13TeV_MLM_5f_max2j_LHE_pythia8_cff.py .

for gridpack in ${GRIDPACKS[@]};do
    NAME=${gridpack%_tarball.tar.xz}
    NAME=${NAME#"$GRIDPACKDIR"\/}
    echo "NAME="$NAME
    ##Make python configuration file##
    echo "@@make configuration python@@"
    make_config.sh -n ${NEVENT} -g ${gridpack} -f Hadronizer_TuneCP5_13TeV_MLM_5f_max2j_LHE_pythia8_cff.py -t ${NAME}
    ##Make tarball##
    echo "@@tar INPUT@@"
    tar -czf INPUT.tar.gz CMSSW* *.py
    JOBDIR=JOBDIR_$NAME
    mkdir -p $JOBDIR
    mv INPUT.tar.gz $JOBDIR
    cd $JOBDIR
    

    echo '#!/bin/bash' > ${NAME}.sh
    echo 'SECTION=`printf %03d $1`' >> ${NAME}.sh
    echo 'WORKDIR=`pwd`'>> ${NAME}.sh
    echo 'echo "#### Extracting cmssw ####"'>> ${NAME}.sh
    echo 'tar -zxvf INPUT.tar.gz'>> ${NAME}.sh
    echo 'echo "#### cmsenv ####"'>> ${NAME}.sh
    echo 'export CMS_PATH=/cvmfs/cms.cern.ch'>> ${NAME}.sh
    echo 'source $CMS_PATH/cmsset_default.sh'>> ${NAME}.sh
    echo 'export SCRAM_ARCH=slc6_amd64_gcc630'>> ${NAME}.sh
    
    echo 'cd CMSSW_9_3_8/src'>> ${NAME}.sh
    echo 'scram build ProjectRename'>> ${NAME}.sh
    echo 'eval `scramv1 runtime -sh`'>> ${NAME}.sh
    echo 'cd ../../'>> ${NAME}.sh
    echo "cmsRun cmsrun_${NAME}.py">> ${NAME}.sh
    
    
    ##Make submit.jds
    echo "@@make_submit_jds@@"
    make_submit_jds.py --runshell ${NAME}.sh --njob $NJOBS --inputtar INPUT.tar.gz
    
    ##submit
    condor_submit submit.jds

    cd $CURDIR/JOBS/

done ##End of for a gridpack

cd $CURDIR