import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../data/data_service.dart';

class Selection {
  static const List<int> options = [3, 5, 7];
}

class MyCustomScroll extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
    BuildContext context,
    Widget child,
    AxisDirection axisDirection,
  ) {
    return GlowingOverscrollIndicator(
      child: child,
      axisDirection: axisDirection,
      color: Colors.deepPurple,
      showLeading: false,
      showTrailing: false,
    );
  }
}

class MyApp extends StatelessWidget {
  final List<int> loadOptions = Selection.options;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.deepPurple),
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

class DataTableWidget extends StatelessWidget {
  final List jsonObjects;
  final List<String> columnNames;
  final List<String> propertyNames;

  DataTableWidget({
    this.jsonObjects = const [],
    this.columnNames = const [],
    this.propertyNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    bool isAscending = false;
    bool isDescending = false;

    if (dataService.temRequisicaoEmCurso()) {
      bool currentAscending = dataService.tableStateNotifier.value['ascending'];

      if (currentAscending) {
        isAscending = true;
      } else {
        isDescending = true;
      }
    }

    return Column(
      children: [
        if (isAscending) Text('Ordenação: Crescente'),
        if (isDescending) Text('Ordenação: Decrescente'),
        DataTable(
          columns: columnNames.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;

            return DataColumn(
              label: Text(
                name,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              onSort: (int columnIndex, bool ascending) {
                String propName = propertyNames[columnIndex];
                dataService.ordenarEstadoAtual(
                  propName,
                  ordemCrescente: ascending,
                );
              },
            );
          }).toList(),
          rows: jsonObjects.map((obj) {
            return DataRow(
              cells: propertyNames.map((propName) {
                return DataCell(
                  Text(obj[propName]),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ],
    );
  }
}
