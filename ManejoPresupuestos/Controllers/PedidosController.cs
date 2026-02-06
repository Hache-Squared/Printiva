using AutoMapper;
using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Controllers
{
    [Permiso("Pedidos")]
    public class PedidosController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioPedidos repositorioPedidos;
        private readonly IRepositorioClientes repositorioClientes;
        private readonly IRepositorioPedidoEstatus repositorioPedidoEstatus;
        private readonly IRepositorioProductos repositorioProductos;
        private readonly IRepositorioCotizaciones repositorioCotizaciones;
        private readonly IMapper mapper;

        public PedidosController(
            IServicioUsuarios servicioUsuarios,
            IRepositorioPedidos repositorioPedidos,
            IRepositorioClientes repositorioClientes,
            IRepositorioPedidoEstatus repositorioPedidoEstatus,
            IRepositorioProductos repositorioProductos,
            IRepositorioCotizaciones repositorioCotizaciones,
            IMapper mapper
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioPedidos = repositorioPedidos;
            this.repositorioClientes = repositorioClientes;
            this.repositorioPedidoEstatus = repositorioPedidoEstatus;
            this.repositorioProductos = repositorioProductos;
            this.repositorioCotizaciones = repositorioCotizaciones;
            this.mapper = mapper;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var pedidos = await repositorioPedidos.ObtenerTodos(usuarioId);
            return View(pedidos);
        }

        [HttpGet]
        public async Task<IActionResult> Detalles(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var pedido = await repositorioPedidos.ObtenerPorId(usuarioId, id);
            if (pedido is null) return RedirectToAction("NoEncontrado", "Home");

            var items = await repositorioPedidos.ObtenerItems(usuarioId, id);

            // Traer cotización ligada al pedido (si existe)
            var cotizaciones = await repositorioCotizaciones.ObtenerTodos(usuarioId, pedidoId: id);
            var cot = cotizaciones?.OrderByDescending(x => x.CotizacionId).FirstOrDefault(); // latest

            var vm = new PedidoDetallesViewModel
            {
                Pedido = pedido,
                Items = items,
                CotizacionId = cot?.CotizacionId,
                CotizacionEstatusNombre = cot?.CotizacionEstatus
            };

            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> Crear()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            var modelo = new PedidoCreacionViewModel
            {
                PedidoEstatusId = 1,
                Items = new List<PedidoItemCreacionViewModel>
                {
                    new PedidoItemCreacionViewModel()
                }
            };

            modelo.Clientes = await ObtenerClientes(usuarioId);
            modelo.Estatus = await ObtenerEstatus();

            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Crear(PedidoCreacionViewModel pedido)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            var cliente = await repositorioClientes.ObtenerPorId(usuarioId, pedido.ClienteId);
            if (cliente is null) return RedirectToAction("NoEncontrado", "Home");

            var estatus = await repositorioPedidoEstatus.ObtenerTodos();
            if (!estatus.Any(x => x.PedidoEstatusId == pedido.PedidoEstatusId)) return RedirectToAction("NoEncontrado", "Home");

            if (pedido.Items is null || !pedido.Items.Any(x => x.ProductoId > 0 && x.Cantidad > 0))
            {
                ModelState.AddModelError(string.Empty, "Agrega al menos un producto con cantidad válida.");
            }

            if (!ModelState.IsValid)
            {
                pedido.Clientes = await ObtenerClientes(usuarioId);
                pedido.Estatus = await ObtenerEstatus();
                if (pedido.Items == null || pedido.Items.Count == 0)
                {
                    pedido.Items = new List<PedidoItemCreacionViewModel> { new PedidoItemCreacionViewModel() };
                }
                return View(pedido);
            }

            var productos = await repositorioProductos.ObtenerTodos(usuarioId);
            var productoIds = new HashSet<int>(productos.Select(x => x.ProductoId));

            if (pedido.Items.Any(x => x.ProductoId > 0 && !productoIds.Contains(x.ProductoId)))
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var pedidoId = await repositorioPedidos.Crear(usuarioId, pedido);
            return RedirectToAction("Detalles", new { id = pedidoId });
        }

        [HttpGet]
        public async Task<IActionResult> Editar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var pedido = await repositorioPedidos.ObtenerPorId(usuarioId, id);
            if (pedido is null) return RedirectToAction("NoEncontrado", "Home");

            var items = await repositorioPedidos.ObtenerItems(usuarioId, id);

            var modelo = mapper.Map<PedidoCreacionViewModel>(pedido);
            modelo.Items = items.Select(mapper.Map<PedidoItemCreacionViewModel>).ToList();

            if (modelo.Items.Count == 0)
            {
                modelo.Items.Add(new PedidoItemCreacionViewModel());
            }

            modelo.Clientes = await ObtenerClientes(usuarioId);
            modelo.Estatus = await ObtenerEstatus();

            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Editar(PedidoCreacionViewModel pedido)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var existente = await repositorioPedidos.ObtenerPorId(usuarioId, pedido.PedidoId);
            if (existente is null) return RedirectToAction("NoEncontrado", "Home");

            var cliente = await repositorioClientes.ObtenerPorId(usuarioId, pedido.ClienteId);
            if (cliente is null) return RedirectToAction("NoEncontrado", "Home");

            pedido.PedidoEstatusId = existente.PedidoEstatusId; 

            if (pedido.Items is null || !pedido.Items.Any(x => x.ProductoId > 0 && x.Cantidad > 0))
            {
                ModelState.AddModelError(string.Empty, "Agrega al menos un producto con cantidad válida.");
            }

            if (!ModelState.IsValid)
            {
                pedido.Clientes = await ObtenerClientes(usuarioId);
                pedido.Estatus = await ObtenerEstatus();
                if (pedido.Items == null || pedido.Items.Count == 0)
                {
                    pedido.Items = new List<PedidoItemCreacionViewModel> { new PedidoItemCreacionViewModel() };
                }
                return View(pedido);
            }

            var productos = await repositorioProductos.ObtenerTodos(usuarioId);
            var productoIds = new HashSet<int>(productos.Select(x => x.ProductoId));

            if (pedido.Items.Any(x => x.ProductoId > 0 && !productoIds.Contains(x.ProductoId)))
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            await repositorioPedidos.Actualizar(usuarioId, pedido);
            return RedirectToAction("Detalles", new { id = pedido.PedidoId });
        }

        [HttpGet]
        public async Task<IActionResult> Borrar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var pedido = await repositorioPedidos.ObtenerPorId(usuarioId, id);
            if (pedido is null) return RedirectToAction("NoEncontrado", "Home");

            return View(pedido);
        }

        [HttpGet]
        public async Task<IActionResult> ProductosActivos()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var productos = await repositorioProductos.ObtenerTodos(usuarioId, true);

            var data = productos.Select(p => new
            {
                productoId = p.ProductoId,
                nombre = p.Nombre,
                categoria = p.ProductoCategoria,
                precioSugerido = p.PrecioSugerido ?? 0
            });

            return Json(data);
        }


        [HttpPost]
        public async Task<IActionResult> BorrarPedido(int pedidoId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var pedido = await repositorioPedidos.ObtenerPorId(usuarioId, pedidoId);
            if (pedido is null) return RedirectToAction("NoEncontrado", "Home");

            await repositorioPedidos.Borrar(usuarioId, pedidoId);
            return RedirectToAction("Index");
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerClientes(int usuarioId)
        {
            var clientes = await repositorioClientes.ObtenerTodos(usuarioId);
            return clientes.Select(x => new SelectListItem(x.Nombre, x.ClienteId.ToString()));
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerEstatus()
        {
            var estatus = await repositorioPedidoEstatus.ObtenerTodos();
            return estatus.Select(x => new SelectListItem(x.Nombre, x.PedidoEstatusId.ToString()));
        }

        [HttpGet]
        public async Task<IActionResult> AccionesDisponibles(int pedidoId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var pedido = await repositorioPedidos.ObtenerPorId(usuarioId, pedidoId);
            if (pedido is null)
                return Json(Array.Empty<PedidoAccionDisponible>());

            var acciones = await repositorioPedidos.ObtenerAccionesDisponibles(usuarioId, pedidoId);
            return Json(acciones);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CambiarEstatus(PedidoCambioEstatusViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var pedido = await repositorioPedidos.ObtenerPorId(usuarioId, modelo.PedidoId);
            if (pedido is null)
                return RedirectToAction("NoEncontrado", "Home");

            if (!ModelState.IsValid)
            {
                TempData["Error"] = "Datos inválidos para cambiar estatus.";
                return RedirectToAction("Detalles", new { id = modelo.PedidoId });
            }

            var result = await repositorioPedidos.CambiarEstatus(usuarioId, modelo.PedidoId, modelo.HaciaEstatusId, modelo.Notas);

            if (result.result != ResultProcedureType.SUCCESS)
                TempData["Error"] = result.message;
            else
                TempData["Success"] = result.message;

            return RedirectToAction("Detalles", new { id = modelo.PedidoId });
        }

        [HttpGet]
        public async Task<IActionResult> Kanban()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            var estatus = await repositorioPedidoEstatus.ObtenerTodos();
            var clientes = await repositorioClientes.ObtenerTodos(usuarioId);

            var vm = new PedidoKanbanViewModel
            {
                Estatus = estatus.Select(x => new PedidoEstatusRow
                {
                    PedidoEstatusId = x.PedidoEstatusId,
                    Nombre = x.Nombre
                }).ToList(),
                Clientes = clientes.Select(x => new SelectListItem(x.Nombre, x.ClienteId.ToString())).ToList()
            };

            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> KanbanData(int clienteId = 0, string q = "", bool soloPendientes = false)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var data = await repositorioPedidos.ObtenerKanban(usuarioId, clienteId, q, soloPendientes);
            return Json(data);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CambiarEstatusAjax(PedidoCambioEstatusViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var pedido = await repositorioPedidos.ObtenerPorId(usuarioId, modelo.PedidoId);
            if (pedido is null)
                return Json(new { ok = false, message = "Pedido no encontrado." });

            var result = await repositorioPedidos.CambiarEstatus(usuarioId, modelo.PedidoId, modelo.HaciaEstatusId, modelo.Notas);

            return Json(new
            {
                ok = result.result == ResultProcedureType.SUCCESS,
                message = result.message
            });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> OcultarEnKanbanAjax(PedidoOcultarKanbanViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            var pedido = await repositorioPedidos.ObtenerPorId(usuarioId, modelo.PedidoId);
            if (pedido is null)
                return Json(new { ok = false, message = "Pedido no encontrado." });

            var res = await repositorioPedidos.OcultarEnKanban(usuarioId, modelo.PedidoId);

            return Json(new
            {
                ok = res.result == ResultProcedureType.SUCCESS,
                message = res.message
            });
        }

    }
}
