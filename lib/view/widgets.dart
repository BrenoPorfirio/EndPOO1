import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../data/data_service.dart';

class Selection {
  static const List<int> options = [3, 5, 15];
}

class CustomScroll extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
    BuildContext context,
    AxisDirection axisDirection,
    Widget child,
  ) {
    return GlowingOverscrollIndicator(
      axisDirection: axisDirection,
      child: child,
      color: Colors.red,
      showTrailing: false,
      showLeading: false,
    );
  }
}

class MyApp extends StatelessWidget {
  final List<int> loadOptions = Selection.options;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.red),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Dicas"),
          actions: [
            PopupMenuButton(
              itemBuilder: (_) => loadOptions
                  .map(
                    (num) => PopupMenuItem(
                      value: num,
                      child: Text("Carregar $num itens por vez"),
                    ),
                  )
                  .toList(),
              onSelected: (number) {
                dataService.numberOfItems = number;
              },
            ),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: dataService.tableStateNotifier,
          builder: (_, value, __) {
            switch (value['status']) {
              case TableStatus.idle:
                return Center(child: Text("Toque em algum botão"));
              case TableStatus.loading:
                return Center(child: CircularProgressIndicator());
              case TableStatus.ready:
                return SingleChildScrollView(
                  child: DataTableWidget(
                    jsonObjects: value['dataObjects'],
                    propertyNames: value['propertyNames'],
                    columnNames: value['columnNames'],
                  ),
                );
              case TableStatus.error:
                return Text("Lascou");
            }
            return Text("...");
          },
        ),
        bottomNavigationBar:
            NewNavBar(itemSelectedCallback: dataService.carregar),
      ),
    );
  }
}

class NewNavBar extends HookWidget {
  final _itemSelectedCallback;

  NewNavBar({itemSelectedCallback})
      : _itemSelectedCallback = itemSelectedCallback ?? (int) {}

  @override
  Widget build(BuildContext context) {
    var state = useState(1);
    return BottomNavigationBar(
        onTap: (index) {
          state.value = index;
          _itemSelectedCallback(index);
        },
        currentIndex: state.value,
        items: const [
          BottomNavigationBarItem(
              label: "Computadores", icon: Icon(Icons.computer_outlined)),
          BottomNavigationBarItem(
              label: "Veículos", icon: Icon(Icons.fire_truck_outlined)),
          BottomNavigationBarItem(
              label: "Comidas", icon: Icon(Icons.fastfood_outlined))
        ]);
  }
}

class DataTableWidget extends HookWidget {
  final List jsonObjects;
  final List<String> columnNames;
  final List<String> propertyNames;

  DataTableWidget(
      {this.jsonObjects = const [],
      this.columnNames = const [],
      this.propertyNames = const []});

  @override
  Widget build(BuildContext context) {
    final sortAscending = useState(true);
    final sortColumnIndex = useState(0);

    return Center(
        child: DataTable(
            sortAscending: sortAscending.value,
            sortColumnIndex: sortColumnIndex.value,
            columns: columnNames
                .map((name) => DataColumn(
                    onSort: (columnIndex, ascending) {
                      sortColumnIndex.value = columnIndex;
                      sortAscending.value = !sortAscending.value;
                      dataService.ordenarEstadoAtual(
                          propertyNames[columnIndex], sortAscending.value);
                    },
                    label: Expanded(
                        child: Text(name,
                            style: TextStyle(fontStyle: FontStyle.italic)))))
                .toList(),
            rows: jsonObjects
                .map((obj) => DataRow(
                    cells: propertyNames
                        .map((propName) => DataCell(Text(obj[propName])))
                        .toList()))
                .toList()));
  }
}

class SearchBar extends StatelessWidget {
  final Icon leading;
  final BoxConstraints constraints;
  final ValueChanged<String> onChanged;

  const SearchBar({
    Key? key,
    required this.leading,
    required this.constraints,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      // Adicionado o Flexible para permitir que o SearchBar ocupe espaço disponível
      child: Container(
        constraints: constraints,
        child: TextField(
          decoration: InputDecoration(
            prefixIcon: leading,
            hintText: 'Pesquisar',
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class MyAppBar extends HookWidget {
  const MyAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var state = useState(7);
    var searchController = useTextEditingController();
    return AppBar(title: Text("Dicas"), actions: [
      SearchBar(
        leading: Icon(
          Icons.search,
          color: Colors.grey,
        ),
        constraints: BoxConstraints(
          minWidth: 1.0,
          maxWidth: 280.0,
        ),
        onChanged: (filter) {
          if (filter.length >= 3) {
            dataService.filtrarEstadoAtual(filter);
          } else {
            dataService.filtrarEstadoAtual('');
          }
        },
      ),
      PopupMenuButton(
        initialValue: state.value,
        itemBuilder: (_) => values
            .map((num) => PopupMenuItem(
                  value: num,
                  child: Text("Carregar $num itens por vez"),
                ))
            .toList(),
        onSelected: (number) {
          state.value = number;
          dataService.numberOfItems = number;
        },
      )
    ]);
  }
}
