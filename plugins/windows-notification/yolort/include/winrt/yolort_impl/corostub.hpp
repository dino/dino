
// Copyright © 2021, mjk <yuubi-san@users.noreply.github.com>

#ifndef YOLORT_IMPL_COROSTUB_HPP
#define YOLORT_IMPL_COROSTUB_HPP

namespace corostub
{
	template<typename=void>
	struct coroutine_handle
	{
		coroutine_handle() = default;
		coroutine_handle( decltype(nullptr) );
		void *address() const;
		void operator()() const {}
		operator bool() const;
		static coroutine_handle<> from_address( ... );
	};

	struct suspend_always {};
	struct suspend_never  {};

	template<typename, typename...>
	struct coroutine_traits;
}

#endif  // YOLORT_IMPL_COROSTUB_HPP

