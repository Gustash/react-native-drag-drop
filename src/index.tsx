import {
  requireNativeComponent,
  UIManager,
  Platform,
  ViewStyle,
} from 'react-native';

const LINKING_ERROR =
  `The package '@gustash/react-native-drag-drop' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

type ReactNativeDragDropProps = {
  color: string;
  style: ViewStyle;
};

const ComponentName = 'ReactNativeDragDropView';

export const ReactNativeDragDropView =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<ReactNativeDragDropProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };
