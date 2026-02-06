using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;

namespace ManejoPresupuestos.Controllers
{
    [Permiso("Clientes")]
    public class ClientesController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioClientes repositorioClientes;

        public ClientesController(IServicioUsuarios servicioUsuarios, IRepositorioClientes repositorioClientes)
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioClientes = repositorioClientes;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var clientes = await repositorioClientes.ObtenerTodos(usuarioId, incluirInactivos: true);
            return View(clientes);
        }

        [HttpGet]
        public IActionResult Crear()
        {
            return View(new ClienteFormViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Crear(ClienteFormViewModel cliente)
        {
            if (!ModelState.IsValid)
                return View(cliente);

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioClientes.Crear(usuarioId, cliente);

            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Editar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var cliente = await repositorioClientes.ObtenerPorId(usuarioId, id);

            if (cliente is null)
                return RedirectToAction("NoEncontrado", "Home");

            var vm = new ClienteFormViewModel
            {
                ClienteId = cliente.ClienteId,
                Nombre = cliente.Nombre,
                Telefono = cliente.Telefono,
                Email = cliente.Email,
                Direccion = cliente.Direccion,
                Instagram = cliente.Instagram,
                WhatsApp = cliente.WhatsApp,
                EstaActivo = cliente.EstaActivo
            };

            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Editar(ClienteFormViewModel cliente)
        {
            if (!ModelState.IsValid)
                return View(cliente);

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            var existe = await repositorioClientes.ObtenerPorId(usuarioId, cliente.ClienteId);
            if (existe is null)
                return RedirectToAction("NoEncontrado", "Home");

            await repositorioClientes.Actualizar(usuarioId, cliente);
            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Borrar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var cliente = await repositorioClientes.ObtenerPorId(usuarioId, id);

            if (cliente is null)
                return RedirectToAction("NoEncontrado", "Home");

            return View(cliente);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> BorrarCliente(int clienteId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioClientes.BorrarLogico(usuarioId, clienteId);
            return RedirectToAction("Index");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ReactivarCliente(int clienteId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioClientes.Reactivar(usuarioId, clienteId);
            return RedirectToAction("Index");
        }
    }
}