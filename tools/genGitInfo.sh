#!/bin/sh
kShortSHA=`git rev-parse --short HEAD`

kCurrentBranch=`git rev-parse --abbrev-ref HEAD`

# A bit verbose, but doesn't fail for missing remotes
kRemoteTracking=`git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD)`

kBuildTime=`date "+%d-%b %H:%M:%S"`

git diff --quiet
if [ $? -ne 0 ]; then
    kIsDirty=YES
else
    kIsDirty=NO
fi

echo "// Git info constants generated by tools/genGitInfo.sh, do not edit!

#define kShortSHA @\"${kShortSHA}\"
#define kCurrentBranch @\"${kCurrentBranch}\"
#define kRemoteTracking @\"${kRemoteTracking}\"
#define kBuildTime @\"${kBuildTime}\"
#define kIsDirty ${kIsDirty}
" > $PROJECT_DIR/shotvibe/GeneratedGitInfo.h


# from http://kylefuller.co.uk/posts/versioning-with-xcode-and-git/

#echo "#define GIT_INFO $gitInfo  $DERIVED_FILE_DIR" > GitInfoPlist.h
#touch $PROJECT_DIR/shotvibe/shotvibe-Info.plist

# TODO: not sure if this is the way to go since it changes bundle version

#defaults write "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH%.*}" "CFBundleShortVersionString" "${gitInfo}"
#defaults write "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH%.*}" "CFBundleVersion" "${COMMITS}"

# Other approaches execute after building, so the git info is always one build behind
# http://www.cimgf.com/2011/02/20/revisiting-git-tags-and-building/
