import os from 'os';
import tar from 'tar';
import path from 'path';
import https from 'https';
import fs from 'fs-extra';
import chalk from 'chalk';
import { Command } from '@expo/commander';
import spawnAsync from '@expo/spawn-async';
import { Config, Simulator, Versions } from '@expo/xdl';

import { STAGING_HOST } from '../Constants';
import { getNewestSDKVersionAsync } from '../ProjectVersions';

type ActionOptions = {
  platform: 'ios' | 'android';
  sdkVersion?: string;
};

async function downloadClientAsync(clientUrl: string): Promise<string> {
  const outputPath = path.join(os.tmpdir(), path.basename(clientUrl));

  if (await fs.exists(outputPath)) {
    console.log(`Found cached client at ${chalk.magenta(outputPath)}`);
    return outputPath;
  }

  return new Promise((resolve, reject) => {
    const output = fs.createWriteStream(outputPath);

    console.log(`Downloading client from ${chalk.magenta(clientUrl)} ...`);

    const request = https.get(clientUrl, response => {
      response.pipe(output);
      output.on('finish', () => output.close(() => resolve(outputPath)));
    });

    request.on('error', error => {
      fs.removeSync(outputPath);
      reject(error);
    });
  });
}

async function extractClientTarballAsync(tarballPath: string): Promise<string> {
  const extractPath = path.join(
    path.dirname(tarballPath),
    path.basename(tarballPath, '.tar.gz'),
  );

  await fs.mkdirs(extractPath);

  console.log(`Extracting client tarball to ${chalk.magenta(extractPath)} ...`);

  await tar.extract({ cwd: extractPath, file: tarballPath });

  return extractPath;
}

async function downloadAndInstallOnIOSAsync(clientUrl: string): Promise<void> {
  const downloadedClientPath = await downloadClientAsync(clientUrl);
  const clientPath = await extractClientTarballAsync(downloadedClientPath);

  console.log(downloadedClientPath, clientPath);
  // await spawnAsync('xcrun', ['simctl', 'install', 'booted', clientPath]);
  // await spawnAsync('xcrun', ['simctl', 'launch', 'booted', 'host.exp.Exponent']);
}

async function action(options: ActionOptions) {
  const sdkVersion = options.sdkVersion || await getNewestSDKVersionAsync(options.platform);

  if (!sdkVersion) {
    throw new Error(`Unable to find newest SDK version. Try to use ${chalk.yellow('--sdkVersion')} flag.`);
  }

  // Set XDL config to use staging
  Config.api.host = STAGING_HOST;

  const versions = await Versions.versionsAsync();
  const sdkConfiguration = versions && versions.sdkVersions && versions.sdkVersions[sdkVersion];

  if (!sdkConfiguration) {
    throw new Error(`Versions configuration for SDK ${chalk.cyan(sdkVersion)} not found!`);
  }

  const tarballKey = `${options.platform}ClientUrl`;
  const clientUrl = sdkConfiguration[tarballKey];

  if (!clientUrl) {
    throw new Error(`Client url not found at ${chalk.yellow(tarballKey)} key of versions config!`);
  }

  if (options.platform === 'ios') {
    await downloadAndInstallOnIOSAsync(clientUrl);
  } else {
    throw new Error(`Platform "${options.platform}" not implemented!`);
  }

  // download tarball
  // unzip

  // iOS
  // xcrun simctl install booted /path/to/your/Exponent.app
  // xcrun simctl launch booted host.exp.Exponent

  // Android
  // adb install
}

export default (program: Command) => {
  program
    .command('install-client')
    .alias('client')
    .description('Installs staging version of the client on iOS simulator, Android emulator or connected Android device.')
    .option('-p, --platform [string]', 'Platform for which the client will be installed.')
    .option('-s, --sdkVersion [string]', 'SDK version of the client to install.')
    .asyncAction(action);
};
