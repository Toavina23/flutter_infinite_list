import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dev_test/domain/entities/item_entity.dart';
import 'package:flutter_dev_test/presentation/blocs/item_list/item_list_bloc.dart';
import 'package:skeletons/skeletons.dart';

class ItemsList extends StatefulWidget {
  const ItemsList({super.key});

  @override
  State<ItemsList> createState() => _ItemsListState();
}

class _ItemsListState extends State<ItemsList> {
  late ScrollController _scrollController;
  late TextEditingController _titleFilterController;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _titleFilterController = TextEditingController();
    _scrollController.addListener(_onScroll);
    _titleFilterController.addListener(_onInputChange);
  }

  _onScroll() {
    var nextPageTrigger = 0.95 * _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= nextPageTrigger &&
        context.read<ItemListBloc>().state.status == ItemListStatus.loaded) {
      context
          .read<ItemListBloc>()
          .add(FetchItemList(searchTitle: _titleFilterController.value.text));
    }
  }

  _onInputChange() {
    if (_titleFilterController.value.text.isEmpty) {
      context.read<ItemListBloc>().add(const FetchItemList());
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _titleFilterController.removeListener(_onInputChange);
    _titleFilterController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My items"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.only(left: 10),
                        fillColor: Colors.grey.shade100,
                        filled: true,
                        hintText: "Please enter search text"),
                    controller: _titleFilterController,
                  ),
                ),
                IconButton(
                    onPressed: () {
                      context.read<ItemListBloc>().add(
                          FilterItemList(_titleFilterController.value.text));
                    },
                    icon: const Icon(Icons.search)),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: BlocBuilder<ItemListBloc, ItemListState>(
            bloc: context.read<ItemListBloc>(),
            builder: (context, state) {
              if (state.status == ItemListStatus.loading &&
                  state.items.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state.status == ItemListStatus.loaded) {
                int itemsCount = state.items.length;
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        separatorBuilder: (context, index) => const SizedBox(
                          height: 20,
                        ),
                        controller: _scrollController,
                        itemCount: itemsCount + 1,
                        itemBuilder: (_, index) {
                          int computedIndex = index;
                          if (computedIndex == itemsCount &&
                              !state.bottomReached) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          ItemEntity currentItem = state.items[computedIndex];
                          return ListTile(
                              title: ItemComponent(
                            item: currentItem,
                          ));
                        },
                      ),
                    ),
                  ],
                );
              } else if (state.status == ItemListStatus.failed) {
                return Center(
                  child: Text(state.failure!.message),
                );
              }
              return Container();
            },
          )),
    );
  }
}

class ItemComponent extends StatelessWidget {
  const ItemComponent({super.key, required this.item});
  final ItemEntity item;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image(
          image: NetworkImage(item.thumbnailUrl),
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame == null) {
              return const SkeletonAvatar(
                style: SkeletonAvatarStyle(
                  height: 150,
                  width: 150,
                ),
              );
            }
            return child;
          },
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                softWrap: true,
              ),
            ),
          ],
        )
      ],
    );
  }
}
