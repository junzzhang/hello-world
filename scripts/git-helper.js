'use strict';

const { exec } = require('child_process');

module.exports = {
    async getCurrentBranch() {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --current-branch', (error, stdout, stderr) => {
                if (error) {
                    return reject((stderr || error.message));
                }
                resolve(stdout.replace(/^\s+|\s+$/, ''));
            })
        })
    },
    async getAllEnableMergeBackBranches(strExcludeBranches) {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --enable-merge-back-branches "' + strExcludeBranches + '"', (error, stdout, stderr) => {
                if (error) {
                    return reject((stderr || error.message));
                }
                resolve(stdout.split(/\s+/).filter(item => !!item));
            })
        })
    },
    async isCurrentBranchClean() {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --is-current-branch-clean', (error, stdout, stderr) => {
                if (error) {
                    return reject(false);
                }
                resolve(stdout.replace(/^\s+|\s+$/, '') === "true");
            })
        })
    },
    async pullCurrentBranch() {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --pull-current-branch', (error, stdout, stderr) => {
                if (error) {
                    return reject(false);
                }
                resolve(stdout.replace(/^\s+|\s+$/, '') === "true");
            })
        })
    },
    async pushCurrentBranch() {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --push-current-branch', (error, stdout, stderr) => {
                if (error) {
                    return reject((stderr || error.message));
                }
                resolve(stdout.replace(/^\s+|\s+$/, '') === "true");
            })
        })
    },
    async mergeFrom(to, from, isPushToOrigin) {
        return new Promise((resolve, reject) => {
            exec(`bash ./scripts/git-helper.sh --merge-from ${to} ${from} ${isPushToOrigin || false}`, (error, stdout, stderr) => {
                if (error) {
                    return resolve(stderr.replace(/^\s+|\s+$/, '') >> 0);
                }
                resolve(stdout.replace(/^\s+|\s+$/, '') >> 0);
            })
        })
    },
    async standardVersion() {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --standard-version', (error, stdout, stderr) => {
                if (error) {
                    return reject((stderr || error.message));
                }
                resolve(stdout.replace(/^\s+|\s+$/, '') === "true");
            })
        })
    },
    async release(currentBranch, tagName, tagDescription, mergeBackBranches) {
        return new Promise((resolve, reject) => {
            const strMergeBackBranches = mergeBackBranches.join(" ");
            const strTagDescription = tagDescription.replace(/\"/g, "\\\"").replace(/\n/g, "\\n");

            const ll = exec(`bash ./scripts/release.sh ${currentBranch} ${tagName} "${strTagDescription}" "${strMergeBackBranches}"`, (error, stdout, stderr) => {
                if (error) {
                    return reject((stderr || error.message));
                }
                resolve(stdout);
            });

            ll.stdout.on('data', (data) => {
                console.log(`stdout: ${data}`);
            });

            ll.stderr.on('data', (data) => {
                console.error(`stderr: ${data}`);
            });
        })
    }
};
