import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:appointment_booking_app/core/constants/app_dimens.dart';
import 'package:appointment_booking_app/core/routes/app_routes.dart';
import 'package:appointment_booking_app/data/models/specialty_model.dart';
import 'package:appointment_booking_app/presentation/auth/cubit/auth_cubit.dart';
import 'package:appointment_booking_app/presentation/home/cubit/home_cubit.dart';
import 'package:appointment_booking_app/presentation/home/cubit/home_state.dart';
import 'package:appointment_booking_app/presentation/home/widgets/doctor_card.dart';
import 'package:appointment_booking_app/presentation/home/widgets/doctor_filter_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<HomeCubit>(),
        child: const DoctorFilterSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.select<AuthCubit, String?>(
      (cubit) => cubit.state.user?.name,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediCare'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(AppRoutes.profile),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state.status == HomeStatus.loading && state.doctors.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == HomeStatus.failure) {
            return _HomeError(onRetry: context.read<HomeCubit>().load);
          }
          return RefreshIndicator(
            onRefresh: context.read<HomeCubit>().load,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      Text(
                        'Hello${userName == null ? '' : ', ${userName.split(' ').first}'}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Find trusted care that fits your schedule.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SearchField(
                        controller: _searchController,
                        onChanged: context.read<HomeCubit>().search,
                        onFilterTap: _showFilters,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Text(
                            'Browse specialties',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.medical_services_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SpecialtyList(
                        specialties: state.specialties,
                        selectedId: state.specialtyId,
                        onSelected: context.read<HomeCubit>().selectSpecialty,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Text(
                            'Recommended for you',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Text(
                            '${state.filteredDoctors.length} found',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (state.filteredDoctors.isEmpty)
                        _EmptyDoctors(
                          onClear: () {
                            _searchController.clear();
                            context.read<HomeCubit>()
                              ..search('')
                              ..clearFilters();
                          },
                        )
                      else
                        ...state.filteredDoctors.map(
                          (doctor) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: DoctorCard(
                              doctor: doctor,
                              onViewDetails: () => context.push(
                                AppRoutes.doctorDetailsPath(doctor.id),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search doctors or specialties',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'Filter doctors',
          icon: const Icon(Icons.tune),
          onPressed: onFilterTap,
        ),
      ),
    );
  }
}

class _SpecialtyList extends StatelessWidget {
  const _SpecialtyList({
    required this.specialties,
    required this.selectedId,
    required this.onSelected,
  });

  final List<SpecialtyModel> specialties;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selectedId == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...specialties.map(
            (specialty) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(specialty.name),
                selected: selectedId == specialty.id,
                onSelected: (selected) =>
                    onSelected(selected ? specialty.id : null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDoctors extends StatelessWidget {
  const _EmptyDoctors({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          children: [
            const Icon(Icons.search_off_outlined, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text('No doctors found',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            const Text('Try changing your search or filters.'),
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
          ],
        ),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text('Could not load doctors',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text('Please check your connection and try again.'),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
