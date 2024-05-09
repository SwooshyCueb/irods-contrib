#!/bin/bash -e

JAVA_MAJOR_VERSION="17"
JDK_VERSION="17.0.11"
JDK_VERSION_LONG="${JDK_VERSION}+7.1"

JDK_ARCHIVE_FILENAME="graalvm-jdk-${JDK_VERSION}_linux-x64_bin.tar.gz"
JDK_ARCHIVE_URL="https://download.oracle.com/graalvm/${JAVA_MAJOR_VERSION}/archive/${JDK_ARCHIVE_FILENAME}"
JDK_DIRNAME="graalvm-jdk-${JDK_VERSION_LONG}"

JRE_BASENAME="graalvm-${JAVA_MAJOR_VERSION}"
JDK_NAME="${JRE_BASENAME}-jdk-amd64"
#JDK_ALIAS="${JDK_DIRNAME}"
JDK_ALIAS="${JDK_NAME}"
JDK_PRIORITY="1799"
JDK_SECTION="non-free"

JDK_PATH="/usr/lib/jvm/${JDK_NAME}"
JINFO_PATH="/usr/lib/jvm/.${JDK_NAME}.jinfo"

declare -A jtools
jtools=(
	["java"]="hl"
	["jexec"]="hl"
	["jfr"]="hl"
	["jrunscript"]="hl"
	["jspawnhelper"]="hl"
	["keytool"]="hl"
	["rmiregistry"]="hl"
	["jar"]="jdkhl"
	["jarsigner"]="jdkhl"
	["javac"]="jdkhl"
	["javadoc"]="jdkhl"
	["javap"]="jdkhl"
	["jcmd"]="jdkhl"
	["jdb"]="jdkhl"
	["jdeprscan"]="jdkhl"
	["jdeps"]="jdkhl"
	["jhsdb"]="jdkhl"
	["jimage"]="jdkhl"
	["jinfo"]="jdkhl"
	["jlink"]="jdkhl"
	["jmap"]="jdkhl"
	["jmod"]="jdkhl"
	["jpackage"]="jdkhl"
	["jps"]="jdkhl"
	["jshell"]="jdkhl"
	["jstack"]="jdkhl"
	["jstat"]="jdkhl"
	["jstatd"]="jdkhl"
	["serialver"]="jdkhl"
	["jconsole"]="jdk"
)

# First, install a jdk package.
# This is just to make sure dependencies are installed and to satisfy package requirements.
# The java-excludes dpkg configuration will prevent any files from actually being written during this step.
apt-get update
apt-get install --no-install-recommends -y openjdk-${JAVA_MAJOR_VERSION}-jdk-headless

# Ensure ca-certificates-java is installed
apt-get install --no-install-recommends -y ca-certificates ca-certificates-java

# Download archive
curl --location --no-progress-meter --output "/tmp/${JDK_ARCHIVE_FILENAME}" "${JDK_ARCHIVE_URL}"

# Extract archive
mkdir -p "${JDK_PATH}"
tar --extract --directory="${JDK_PATH}" --strip-components=1 --file="/tmp/${JDK_ARCHIVE_FILENAME}"
#ln -s "${JDK_NAME}" "/usr/lib/jvm/${JDK_ALIAS}"

# Remove archive
rm "/tmp/${JDK_ARCHIVE_FILENAME}"

# Remove some stuff we don't care about
find "${JDK_PATH}" -type d -name 'include' -exec -rm -r "{}" +
find "${JDK_PATH}" -type d -name 'clibraries*' -exec -rm -r "{}" +
rm -r "${JDK_PATH}/lib/static"
rm -r "${JDK_PATH}/man"

# Generate redirector scripts (work around bug JDK-8314491)
jtools_lib=("jexec" "jspawnhelper")
for jtool in "${!jtools_lib[@]}"; do
	cat <<- EOF > "${JDK_PATH}/bin/${jtool}"
	#!/usr/bin/env bash

	SOURCE=\${BASH_SOURCE[0]}
	while [ -L "\$SOURCE" ]; do
	  SCRIPT_DIR=\$( cd -P "\$( dirname "\$SOURCE" )" >/dev/null 2>&1 && pwd )
	  SOURCE=\$(readlink "\$SOURCE")
	  [[ \$SOURCE != /* ]] && SOURCE=\$DIR/\$SOURCE
	done
	SCRIPT_DIR=\$( cd -P "\$( dirname "\$SOURCE" )" >/dev/null 2>&1 && pwd )

	exec "\${SCRIPT_DIR}/../lib/${jtool}" "\$@"
	EOF
	chmod +x "${JDK_PATH}/bin/${jtool}"
done

# Generate jar binfmt
cat << EOF > "${JDK_PATH}/lib/jar.binfmt"
package ${JRE_BASENAME}
interpreter /usr/bin/jexec
magic PK\\x03\\x04
EOF

# Generate .jinfo file
cat << EOF > "${JINFO_PATH}"
name=${JDK_NAME}
alias=${JDK_ALIAS}
priority=${JDK_PRIORITY}
section=${JDK_SECTION}

EOF
for jtool in "${!jtools[@]}"; do
	echo "${jtools[$jtool]} ${jtool} ${JDK_PATH}/bin/${jtool}" >> "${JINFO_PATH}"
done

# update alternatives
unset jtools["jexec"] # jexec has special handling
for jtool in "${!jtools[@]}"; do
	update-alternatives --install \
		"/usr/bin/${jtool}" \
		"${jtool}" \
		"${JDK_PATH}/bin/${jtool}" \
		"${JDK_PRIORITY}"
done
update-alternatives --install \
	"/usr/bin/jexec" \
	"jexec" \
	"${JDK_PATH}/bin/jexec" \
	"${JDK_PRIORITY}" \
	--slave "/usr/share/binfmnts/jar" \
	"jexec-binfmt" \
	"${JDK_PATH}/lib/jar.binfmt"

# try to register binfmt
if which update-binfmts >/dev/null && [ -r /usr/share/binfmts/jar ]; then
	update-binfmts --package "${JRE_BASENAME}" --import jar || true
fi

# update ca certs
dpkg-trigger --by-package=graalvm-jdk-17 update-ca-certificates-java

# cleanup
rm -rf /tmp/*