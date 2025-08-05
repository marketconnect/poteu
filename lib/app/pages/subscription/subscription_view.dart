import 'package:flutter/material.dart' hide View;
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';
import 'subscription_controller.dart';
import '../../widgets/regulation_app_bar.dart';

class SubscriptionView extends View {
  final SubscriptionRepository subscriptionRepository;

  const SubscriptionView({Key? key, required this.subscriptionRepository})
      : super(key: key);

  @override
  SubscriptionViewState createState() =>
      SubscriptionViewState(subscriptionRepository);
}

class SubscriptionViewState
    extends ViewState<SubscriptionView, SubscriptionController> {
  SubscriptionViewState(SubscriptionRepository subscriptionRepository)
      : super(SubscriptionController(subscriptionRepository));

  @override
  Widget get view {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          Theme.of(context).appBarTheme.toolbarHeight ?? 74.0,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
          ),
          child: RegulationAppBar(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    size: Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
                    color: Theme.of(context).appBarTheme.iconTheme?.color,
                  ),
                ),
                const Expanded(
                  child: Text('Оформить подписку', textAlign: TextAlign.center),
                ),
                const SizedBox(width: 48), // To balance the back button
              ],
            ),
          ),
        ),
      ),
      body: ControlledWidgetBuilder<SubscriptionController>(
        builder: (context, controller) {
          if (controller.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Создаем ссылку на оплату...'),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.workspace_premium,
                    size: 80, color: Colors.amber),
                const SizedBox(height: 24),
                Text(
                  'Доступ к дополнительным документам',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Подписка открывает доступ ко всем документам в библиотеке.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 48),
                _buildPlanButton(
                  context,
                  controller,
                  title: '1 месяц',
                  price: '100 ₽',
                  planType: 'monthly',
                ),
                const SizedBox(height: 16),
                _buildPlanButton(
                  context,
                  controller,
                  title: '1 год',
                  price: '600 ₽',
                  planType: 'yearly',
                ),
                if (controller.error != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Ошибка: ${controller.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanButton(
      BuildContext context, SubscriptionController controller,
      {required String title,
      required String price,
      required String planType}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            Theme.of(context).navigationRailTheme.selectedIconTheme?.color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () => controller.purchase(planType),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.normal)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(price, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
