'use strict';

const { exec, spawn } = require('child_process');

exec('bash ./scripts/t.sh', (error, stdout, stderr) => {
    if (error) {
        console.log("stderr = ", stderr);
        return;
    }

    console.log("stdout = ", stdout);
});
