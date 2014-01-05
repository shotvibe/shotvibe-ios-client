# from http://kylefuller.co.uk/posts/versioning-with-xcode-and-git/

# TODO: not sure if this is the way to go since it changes bundle version
shortSHA=`git rev-parse --short HEAD`
isDirty=`git diff --quiet || echo "(*)"`
currentBranch=`git rev-parse --abbrev-ref HEAD`
#remoteTracking=`git rev-parse --symbolic-full-name --abbrev-ref @{u}`
remoteTracking=`git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD)`
#gitInfo="${currentBranch}:${remoteTracking}:#${shortSHA}${isDirty}"
gitInfo=`date`
#echo "#define GIT_INFO $gitInfo  $DERIVED_FILE_DIR" > GitInfoPlist.h
#touch $PROJECT_DIR/shotvibe/shotvibe-Info.plist
#echo blabla > $DERIVED_FILE_DIR/bla

defaults write "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH%.*}" "CFBundleShortVersionString" "${gitInfo}"
#defaults write "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH%.*}" "CFBundleVersion" "${COMMITS}"

# Other approaches execute after building, so the git info is always one build behind
# http://www.cimgf.com/2011/02/20/revisiting-git-tags-and-building/
