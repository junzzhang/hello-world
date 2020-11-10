'use strict';

const { exec } = require('child_process');

module.exports = {
    async getCurrentBranch() {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --current-branch', (error, stdout, stderr) => {
                if (error) {
                    reject(error);
                }
                resolve(stdout.replace(/^\s+|\s+$/, ''));
            })
        })
    },
    async getAllEnableMergeBackBranches(strExcludeBranches) {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --enable-merge-back-branches "' + strExcludeBranches + '"', (error, stdout, stderr) => {
                if (error) {
                    reject(error);
                }
                resolve(stdout.split(/\s+/).filter(item => !!item));
            })
        })
    },
    async isCurrentBranchClean() {
        return new Promise((resolve, reject) => {
            exec('bash ./scripts/git-helper.sh --is-current-branch-clean', (error, stdout, stderr) => {
                if (error) {
                    reject(error);
                }
                resolve(stdout.replace(/^\s+|\s+$/, '') === "true");
            })
        })
    },
    async release(currentBranch, tagName, tagDescription, mergeBackBranches) {
        return new Promise((resolve, reject) => {
            const strMergeBackBranches = mergeBackBranches.join(" ");
            exec(`bash ./scripts/release.sh ${currentBranch} ${tagName} ${tagDescription} "${strMergeBackBranches}"`, (error, stdout, stderr) => {
                if (error) {
                    reject(error);
                }
                resolve(stdout);
            })
        })
    }
};
