import 'package:flutter/material.dart';
import 'contract_list_item.dart';

class ContractList extends StatelessWidget {
  final List<dynamic> contracts;
  final Function(String) onPhoneCall;
  final Function(dynamic) onShowDetail;

  ContractList({
    required this.contracts,
    required this.onPhoneCall,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 12),
      itemCount: contracts.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey.shade400),
      itemBuilder: (context, index) {
        final contract = contracts[index];
        return ContractListItem(
          contract: contract,
          onPhoneCall: onPhoneCall,
          onShowDetail: () => onShowDetail(contract),
        );
      },
    );
  }
}
