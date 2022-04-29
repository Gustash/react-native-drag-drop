import * as React from 'react';

import {Image, StyleSheet, View} from 'react-native';
import {DropItem, DropTargetView} from '@gustash/react-native-drag-drop';
import {FlatList} from 'react-native';

export default function App() {
  const [items, setItems] = React.useState<DropItem[]>([]);

  return (
    <View style={styles.container}>
      <FlatList
        data={items}
        keyExtractor={({filename, data}) => filename || data}
        renderItem={({item}) => {
          if (!item.type.startsWith('image/')) {
            return null;
          }

          return <Image style={styles.image} source={{uri: item.data}} />;
        }}
      />
      <DropTargetView
        color="#32a852"
        style={styles.box}
        onDrop={e => {
          console.log(e.nativeEvent.items);
          setItems(currItems => [...currItems, ...e.nativeEvent.items]);
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
  image: {
    width: 300,
    height: 300,
  },
});
