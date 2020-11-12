'use strict';

const { exec } = require('child_process');
const SCRIPTS_PATH = './scripts/release/git-helper.sh';

async function runCmd(cmd) {
    return new Promise((resolve, reject) => {
        exec(cmd, (error, stdout, stderr) => {
            if (error) {
                const err = new Error((stderr || stdout).replace(/^\s+|\s+$/, ''));
                Object.assign(err, error);
                return reject(err);
            }
            resolve((stdout || '').replace(/^\s+|\s+$/, ''));
        });
    });
}

module.exports = {
    async getCurrentBranch() {
        return runCmd(`bash ${SCRIPTS_PATH} --current-branch`);
    },
    async getAllEnableMergeBackBranches(strExcludeBranches) {
        return runCmd(`bash ${SCRIPTS_PATH} --enable-merge-back-branches "` + strExcludeBranches + '"').then(result => {
            return result.split(/\s+/).filter(item => !!item)
        });
    },
    async isCurrentBranchClean() {
        return runCmd(`bash ${SCRIPTS_PATH} --is-current-branch-clean`).then(result => result === "true");
    },
    async pullCurrentBranch() {
        return runCmd(`bash ${SCRIPTS_PATH} --pull-current-branch`).then(() => true);
    },
    async pushCurrentBranch() {
        return runCmd(`bash ${SCRIPTS_PATH} --push-current-branch`).then(() => true);
    },
    async removeRemoteBranch(localBranchName) {
        return runCmd(`bash ${SCRIPTS_PATH} --remove-remote-branch ${localBranchName}`)
            .then(() => true).catch(() => false);
    },
    async removeLocalBranch(localBranchName) {
        return runCmd(`bash ${SCRIPTS_PATH} --remove-local-branch ${localBranchName}`)
            .then(() => true).catch(() => false);
    },
    async mergeFrom(to, from, isPushToOrigin) {
        return runCmd(`bash ${SCRIPTS_PATH} --merge-from ${to} ${from} ${isPushToOrigin || false}`)
            .then(() => 0).catch(err => {
                // console.log('\n err = ', err.message);
                return err.code;
            });
    },
    async standardVersion() {
        return runCmd(`bash ${SCRIPTS_PATH} --standard-version`)
            .then(() => true);
    },
    async createLocalTag(tag, tagDescription) {
        const strDesc = (tagDescription || tag).replace(/\"/g, "\\\"").replace(/\n/g, '" -m "');
        const cmd = `git tag -a ${tag} -m "${strDesc}"`;

        return runCmd(cmd).then(() => {
            return runCmd("git push --follow-tags origin master")
        }).then(() => true);
    }
};
