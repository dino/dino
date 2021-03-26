#pragma once

template<typename T>
struct ComPtr
{
    T *p{};

    ~ComPtr() { if (p != nullptr) p->Release(); }

    T  &operator*() const { return *p; }
    T **operator&() const { return &p; }
    T **operator&()       { return &p; }
    T *operator->() const { return  p; }

    template<typename U>
    HRESULT As( U **const pp ) const
    { return p->QueryInterface(pp); }
};