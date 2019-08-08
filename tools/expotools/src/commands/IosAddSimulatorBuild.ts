import aws from 'aws-sdk';
import { UpdateVersions, Config } from '@expo/xdl';
import { iosAppVersionAsync } from '../ProjectVersions';

type ActionOptions = {
  app: string;
  appVersion?: string;
};

async function action(options: ActionOptions) {
  if (!options.app) {
    throw new Error('Must run with `--app PATH_TO_APP`');
  }
  const appVersion = options.appVersion || await iosAppVersionAsync();
  const s3 = new aws.S3({ region: 'us-east-1' });

  Config.api.host = 'staging.expo.io';
  await UpdateVersions.updateIOSSimulatorBuild(s3, options.app, appVersion);
}

export default (program: any) => {
  program
    .command('ios-add-simulator-build')
    .alias('ios-add-sim')
    .description('Uploads simulator build to S3 and updates `iosExpoViewUrl` in versions endpoint.')
    .option('--app <string>', 'Path to the Exponent.app archive.')
    .option('--appVersion [string]', 'iOS app version. Defaults to `CFBundleShortVersionString` in project\'s Info.plist.')
    .asyncAction(action);
};
