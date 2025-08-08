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
          Widget body;
          if (controller.isLoadingPlans) {
            body = const Center(child: CircularProgressIndicator());
          } else if (controller.error != null && controller.plans.isEmpty) {
            body = Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ошибка загрузки тарифов: ${controller.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.fetchPlans,
                      child: const Text('Попробовать снова'),
                    )
                  ],
                ),
              ),
            );
          } else {
            body = Padding(
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
                  ..._buildPlanWidgets(context, controller),
                  if (controller.error != null && controller.plans.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      '${controller.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ]
                ],
              ),
            );
          }

          return Stack(
            children: [
              body,
              if (controller.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)),
                        SizedBox(height: 16),
                        Text('Создаем ссылку на оплату...',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildPlanWidgets(
      BuildContext context, SubscriptionController controller) {
    final widgets = <Widget>[];
    for (var i = 0; i < controller.plans.length; i++) {
      final plan = controller.plans[i];
      widgets.add(_buildPlanButton(
        context,
        controller,
        title: plan.title,
        price: plan.price,
        planType: plan.planType,
      ));
      if (i < controller.plans.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }
    return widgets;
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
