/// Auth domain providers — réexport du core pour éviter un 2e ApiClient.
export '../../../core/providers/providers.dart'
    show authProvider, apiClientProvider, authRepositoryProvider, AuthState, AuthNotifier;
