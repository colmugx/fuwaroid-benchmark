#include <caf/all.hpp>

#include <cstdint>
#include <cstdlib>
#include <stdexcept>
#include <string>

caf::behavior counter(caf::event_based_actor* self) {
  auto count = std::make_shared<std::uint64_t>(0);
  return {
    [count](std::uint8_t) {
      ++(*count);
    },
    [self, count](const std::string&) -> std::uint64_t {
      auto result = *count;
      self->quit();
      return result;
    },
  };
}

void caf_main(caf::actor_system& sys) {
  const char* raw = std::getenv("MESSAGES");
  auto n = raw ? std::strtoull(raw, nullptr, 10) : 1000000ULL;

  auto worker = sys.spawn(counter);
  for (std::uint64_t i = 0; i < n; ++i)
    caf::anon_mail(std::uint8_t{1}).send(worker);

  caf::scoped_actor self{sys};
  std::uint64_t got = 0;
  self->mail(std::string{"barrier"})
    .request(worker, caf::infinite)
    .receive(
      [&](std::uint64_t value) { got = value; },
      [&](const caf::error& err) { throw std::runtime_error(caf::to_string(err)); });

  if (got != n)
    throw std::runtime_error("count mismatch");
}

CAF_MAIN()
