'use strict';
const inquirer = require('inquirer');
const {
    isCurrentBranchClean,
    getCurrentBranch,
    getAllEnableMergeBackBranches,
    pullCurrentBranch,
    pushCurrentBranch,
    mergeFrom,
    standardVersion,
    createLocalTag,
    removeRemoteBranch,
    removeLocalBranch
} = require('./git-utils');
const BottomBar = require('inquirer/lib/ui/bottom-bar');

function logTips(str) {
    console.log("\x1b[33m%s\x1b[0m", str);
}

async function start() {
    const currentBranch = await getCurrentBranch();
    const { isPublish } = await inquirer.prompt([
        {
            type: 'confirm',
            name: 'isPublish',
            message: `确定要发布当前分支 ${currentBranch} 吗？`,
            default: false,
        }
    ]);

    if (!isPublish) {
        throw new Error('您取消了发布当前分支。');
    }

    const isClean = await isCurrentBranchClean();
    if (!isClean) {
        throw new Error('请确保当前分支是干净的并且与远程代码同步，才可发布当前分支。');
    }

    let defaultTag = currentBranch.match(/(\d+\.){3}\d+/) || void 0;
    if (defaultTag) {
        defaultTag = defaultTag[0];
    }
    const enableMergeBackbranches = await getAllEnableMergeBackBranches(currentBranch);

    const questions = [
        {
            type: 'input',
            name: 'tagName',
            message: '请输入 tag 号：',
            default: defaultTag,
            validate: function (value) {
                if (/^(\d+\.){3}\d+$/.test(value)) {
                    return true;
                }

                return '请输入正确的版本号！';
            },
        },
        {
            type: 'editor',
            name: 'tagDescription',
            message: '请输入 tag 描述信息：',
            validate: function (text) {
                if (!(text.replace(/^\s+|\s+$/, ''))) {
                    return 'Tag 描述信息不能为空.';
                }

                return true;
            },
        },
        {
            type: 'checkbox',
            message: '请选择发布完成后，想要回合的分支：',
            name: 'mergeBackBranches',
            choices: enableMergeBackbranches.map(item => ({name: item})),
            default: enableMergeBackbranches,
            validate: function (answer) {
                // if (answer.length < 1) {
                //     return 'You must choose at least one topping.';
                // }
                return true;
            },
        }
    ];

    const { tagName, tagDescription, mergeBackBranches } = await inquirer.prompt(questions);

    logTips("正在拉取远程仓库状态...");
    if (!(await pullCurrentBranch())) {
        throw new Error(`当前分支 ${currentBranch} 更新失败，请手动处理完冲突，再重新发布。`);
    }
    logTips("远程仓库状态拉取完毕。");

    logTips("正在生成更新日志 CHANGELOG.md、升级版本号...");
    if (!(await standardVersion())) {
        throw new Error("生成更新日志，升级版本号失败；解决完此问题，可重新发布。");
    }
    logTips("更新日志 CHANGELOG.md、版本号升级 完毕。");

    if (currentBranch !== "master") {
        logTips(`正在将当前分支 ${currentBranch} 代码推至远程代码仓库...`);
        if (!(await pushCurrentBranch())) {
            throw new Error(`当前分支 ${currentBranch} 代码没有成功推入远程仓库，接下来你最好手动进行发版操作。`);
        }
        logTips(`将当前分支 ${currentBranch} 代码已推至远程代码仓库。`);

        logTips(`将当前分支 ${currentBranch} 合并至 master 分支...`);
        if ((await mergeFrom("master", currentBranch)) !== 0) {
            throw new Error(`分支 ${currentBranch} 代码没有成功合并入 master 分支，接下来你最好手动进行发版操作。`)
        }
        logTips(`当前分支 ${currentBranch} 合并至 master 分支完毕。`);
    }

    logTips(`正在创建本地 Tag ${tagName}...`);
    if (!(await createLocalTag(tagName, tagDescription))) {
        throw new Error(`创建本地 tag ${tagName} 失败；接下来你最好手动进行发版操作。`);
    }
    logTips(`本地 Tag ${tagName} 创建完毕。`);

    if (currentBranch !== "master") {
        logTips(`删除远程分支 ${currentBranch}...`);
        if (!(await removeRemoteBranch(currentBranch))) {
            console.log("\x1b[31m%s\x1b[0m", `远程分支 ${currentBranch} 删除失败，稍后请稍后手动删除。`);
        } else {
            logTips(`远程分支 ${currentBranch} 删除完毕。`);
        }

        logTips(`删除本地分支 ${currentBranch}...`)
        if (!(await removeLocalBranch(currentBranch))) {
            console.log("\x1b[31m%s\x1b[0m", `本地分支 ${currentBranch} 删除失败，稍后请稍后手动删除。`)
        } else {
            logTips(`本地分支 ${currentBranch} 删除完毕。`);
        }
    }

    if (mergeBackBranches.length) {
        const ui = new BottomBar({ bottomBar: `正在回合代码：${mergeBackBranches.length}/0` });
        const successBranches = await mergeBack(mergeBackBranches, 0, [], (i) => {
            ui.updateBottomBar(`正在回合代码：${mergeBackBranches.length}/${i + 1}`);
        });
        ui.close();
        logTips("\n");

        if (successBranches.length) {
            logTips(`回合成功的分支有 ${successBranches.length} 个，如下所示：\n`);
            successBranches.forEach(item => {
                logTips(item);
            });
            logTips("\n");
        }

        const failBranches = mergeBackBranches.filter(item => successBranches.findIndex(name => name === item) === -1);
        if (failBranches.length) {
            logTips(`回合失败的分支有 ${failBranches.length} 个，如下所示：\n`);
            failBranches.forEach(item => {
                console.log("\x1b[31m%s\x1b[0m", item);
            });
            logTips("\n");
        }
    }

    logTips('发布完成。\n');
}

/**
 * 回合代码
 * @param asyncFuncs -
 * @param currentIndex -
 * @returns {Promise<undefined|*>}
 */
async function mergeBack(mergeBackBranches, currentIndex, successBranches, callback) {
    if (currentIndex >= mergeBackBranches.length) {
        return successBranches;
    }
    const branch = mergeBackBranches[currentIndex];
    const status = await mergeFrom(branch, "master", true);
    switch (status) {
        case 0: // 成功
            callback(currentIndex);
            successBranches.push(branch);
            return await mergeBack(mergeBackBranches, ++currentIndex, successBranches, callback);
        case 2: // 终止回合
            callback(currentIndex);
            return successBranches;
        default: // 失败
            callback(currentIndex);
            return mergeBack(mergeBackBranches, ++currentIndex, successBranches, callback);
    }
}

start().catch(err => {
    console.log("\n\x1b[31m发布失败：%s\x1b[0m", err.message || err);
});
