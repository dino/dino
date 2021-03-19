
#ifndef OVERLOAD_HPP
#define OVERLOAD_HPP
template<typename... Callable>
struct overload : Callable...
{
    overload(Callable &&... c) : Callable{std::move(c)}... {}
    using Callable::operator()...;
};
#endif
