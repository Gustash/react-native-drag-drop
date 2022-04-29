import {
  requireNativeComponent,
  UIManager,
  Platform,
  ViewStyle,
  NativeSyntheticEvent,
} from 'react-native';

const LINKING_ERROR =
  `The package '@gustash/react-native-drag-drop' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

export type DropItem = {
  data: string;
  type: string;
  filename?: string;
};
export type DropEvent = {
  items: DropItem[];
};

export interface ReactNativeDropViewProps {
  color: string;
  onDrop: (e: NativeSyntheticEvent<DropEvent>) => void;
  style: ViewStyle;
}

const ComponentName = 'RNDDDropTargetView';

const DropTargetView =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<ReactNativeDropViewProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };

export default DropTargetView;
