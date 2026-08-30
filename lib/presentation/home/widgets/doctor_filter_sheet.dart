import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/presentation/home/cubit/home_cubit.dart';
import 'package:appointment_booking_app/presentation/home/cubit/home_state.dart';

class DoctorFilterSheet extends StatelessWidget {
  const DoctorFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Filters',
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: context.read<HomeCubit>().clearFilters,
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Minimum rating',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [4.0, 4.5, 4.8]
                      .map(
                        (rating) => ChoiceChip(
                          label: Text('$rating+'),
                          selected: state.minRating == rating,
                          onSelected: (selected) => context
                              .read<HomeCubit>()
                              .setMinimumRating(selected ? rating : null),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available doctors only'),
                  subtitle:
                      const Text('Hide doctors with no upcoming availability'),
                  value: state.availableOnly,
                  onChanged: context.read<HomeCubit>().setAvailableOnly,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Show results'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
