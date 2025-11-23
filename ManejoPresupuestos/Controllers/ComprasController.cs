using AutoMapper;
using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Controllers
{
    public class ComprasController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioCompraTipos repositorioCompraTipos;
        private readonly IRepositorioFilamentoTipos repositorioFilamentoTipos;
        private readonly IRepositorioCompraCategorias repositorioCompraCategorias;
        private readonly IRepositorioCompras repositorioCompras;

        private readonly IRepositorioInventarios repositorioInventarios;
        private readonly IRepositorioInventarioMarcas repositorioInventarioMarcas;
        private readonly IRepositorioInventarioTipos repositorioInventarioTipos;
        private readonly IRepositorioInventarioColores repositorioInventarioColores;
        private readonly IRepositorioInventarioNombres repositorioInventarioNombres;
        private readonly IRepositorioInventarioUnidades repositorioInventarioUnidades;

        private readonly IMapper mapper;

        public ComprasController(
            IServicioUsuarios servicioUsuarios,
            IRepositorioCompraTipos repositorioCompraTipos,
            IRepositorioFilamentoTipos repositorioFilamentoTipos,
            IRepositorioCompraCategorias repositorioCompraCategorias,
            IRepositorioCompras repositorioCompras,
            IRepositorioInventarios repositorioInventarios,
            IRepositorioInventarioMarcas repositorioInventarioMarcas,
            IRepositorioInventarioTipos repositorioInventarioTipos,
            IRepositorioInventarioColores repositorioInventarioColores,
            IRepositorioInventarioNombres repositorioInventarioNombres,
            IRepositorioInventarioUnidades repositorioInventarioUnidades,
            IMapper mapper
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioCompraTipos = repositorioCompraTipos;
            this.repositorioFilamentoTipos = repositorioFilamentoTipos;
            this.repositorioCompraCategorias = repositorioCompraCategorias;
            this.repositorioCompras = repositorioCompras;
            this.repositorioInventarios = repositorioInventarios;
            this.repositorioInventarioMarcas = repositorioInventarioMarcas;
            this.repositorioInventarioTipos = repositorioInventarioTipos;
            this.repositorioInventarioColores = repositorioInventarioColores;
            this.repositorioInventarioNombres = repositorioInventarioNombres;
            this.repositorioInventarioUnidades = repositorioInventarioUnidades;
            this.mapper = mapper;
        }

        [HttpGet]
        async public Task<IActionResult> Index()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var compras = await repositorioCompras.ObtenerTodos(usuarioId);
            return View(compras);
        }

        async public Task<IActionResult> Tipos()
        {
            var tipos = await this.repositorioCompraTipos.ObtenerTodos();
            return View(tipos);
        }

        async public Task<IActionResult> Filamentos()
        {
            var filamentos = await this.repositorioFilamentoTipos.ObtenerTodos();
            return View(filamentos);
        }

        async public Task<IActionResult> Categorias()
        {
            var categorias = await this.repositorioCompraCategorias.ObtenerTodos();
            return View(categorias);
        }

        [HttpGet]
        public async Task<IActionResult> Crear()
        {
            var modelo = new CompraCreacionViewModel();
            modelo.Tipos = await ObtenerTipos();
            modelo.FilamentoTipos = await ObtenerFilamentos();
            modelo.Categorias = await ObtenerCategorias();
            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Crear(CompraCreacionViewModel compra)
        {
            // Validaciones
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var tipo = await repositorioCompraTipos.ObtenerPorId(compra.CompraTipoId);
            var categoria = await repositorioCompraCategorias.ObtenerPorId(compra.CompraCategoriaId);
            var filamento = await repositorioFilamentoTipos.ObtenerPorId(compra.FilamentoTipoId ?? -1);
            if (
                tipo is null ||
                categoria is null ||
                (compra.FilamentoTipoId.HasValue && filamento is null)
            )
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            if (!ModelState.IsValid)
            {
                compra.Tipos = await ObtenerTipos();
                compra.FilamentoTipos = await ObtenerFilamentos();
                compra.Categorias = await ObtenerCategorias();
                return View(compra);
            }
            await repositorioCompras.Crear(compra);
            await repositorioCompras.CompraLogTransaccion(usuarioId, compra);

            if (tipo.Nombre == "Filamento" || tipo.Nombre == "Herramienta")
            {
                var marcas = await repositorioInventarioMarcas.ObtenerTodos();
                var tipos = await repositorioInventarioTipos.ObtenerTodos();
                var colores = await repositorioInventarioColores.ObtenerTodos();
                var nombres = await repositorioInventarioNombres.ObtenerTodos();
                var unidades = await repositorioInventarioUnidades.ObtenerTodos();

                if (!marcas.Any() || !tipos.Any() || !colores.Any() || !nombres.Any() || !unidades.Any())
                {
                    return RedirectToAction("Crear", "Inventarios");
                }

                var marcaId = marcas.Any() ? marcas.First().InventarioMarcaId : -1;
                var tipoId = tipos.Any() ? tipos.First().InventarioTipoId : -1;
                var colorId = colores.Any() ? colores.First().InventarioColorId : -1;
                var nombreId = nombres.Any() ? nombres.First().InventarioNombreId : -1;
                var unidadId = unidades.Any() ? unidades.First().InventarioUnidadId : -1;

                var nuevoInventario = new Inventario
                {
                    Cantidad = 0,
                    InventarioMarcaId = marcaId,
                    InventarioTipoId = tipoId,
                    InventarioColorId = colorId,
                    InventarioNombreId = nombreId,
                    InventarioUnidadId = unidadId,
                    FechaCreacion = DateTime.Now
                };

                await repositorioInventarios.Crear(nuevoInventario);

                return RedirectToAction("Editar", "Inventarios", new { id = nuevoInventario.InventarioId });
            }

            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Editar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var compra = await repositorioCompras.ObtenerPorId(usuarioId, id);
            if (compra is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var modelo = mapper.Map<CompraCreacionViewModel>(compra);
            modelo.Tipos = await ObtenerTipos();
            modelo.FilamentoTipos = await ObtenerFilamentos();
            modelo.Categorias = await ObtenerCategorias();
            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Editar(CompraCreacionViewModel compraEditar)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var compra = await repositorioCompras.ObtenerPorId(usuarioId, compraEditar.CompraId);
            if (compra is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            // Validaciones
            var tipo = await repositorioCompraTipos.ObtenerPorId(compraEditar.CompraTipoId);
            var categoria = await repositorioCompraCategorias.ObtenerPorId(compraEditar.CompraCategoriaId);
            var filamento = await repositorioFilamentoTipos.ObtenerPorId(compraEditar.FilamentoTipoId ?? -1);
            if (
                tipo is null ||
                categoria is null ||
                (compraEditar.FilamentoTipoId.HasValue && filamento is null)
            )
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            if (!ModelState.IsValid)
            {
                compraEditar.Tipos = await ObtenerTipos();
                compraEditar.FilamentoTipos = await ObtenerFilamentos();
                compraEditar.Categorias = await ObtenerCategorias();
                return View(compraEditar);
            }
            await repositorioCompras.Actualizar(usuarioId, compraEditar);
            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Borrar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var compra = await repositorioCompras.ObtenerPorId(usuarioId, id);
            if (compra is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(compra);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarCompra(int compraId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var compra = await repositorioCompras.ObtenerPorId(usuarioId, compraId);
            if (compra is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            await repositorioCompras.Borrar(usuarioId, compraId);
            return RedirectToAction("Index");
        }

        [HttpGet]
        public IActionResult CrearTipo()
        {
            return View(null);
        }

        [HttpPost]
        async public Task<IActionResult> CrearTipo(CompraTipo tipo)
        {
            if (!ModelState.IsValid)
            {
                return View(tipo);
            }

            await repositorioCompraTipos.Crear(tipo);
            return RedirectToAction("Tipos");
        }

        [HttpGet]
        public async Task<IActionResult> EditarTipo(int id)
        {
            var tipo = await repositorioCompraTipos.ObtenerPorId(id);
            if (tipo is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(tipo);
        }

        [HttpPost]
        public async Task<IActionResult> EditarTipo(CompraTipo tipoEditar)
        {
            if (!ModelState.IsValid)
            {
                return View(tipoEditar);
            }

            var tipo = await repositorioCompraTipos.ObtenerPorId(tipoEditar.CompraTipoId);
            if (tipo is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioCompraTipos.Actualizar(usuarioId, tipoEditar);
            return RedirectToAction("Tipos");
        }

        [HttpGet]
        public async Task<IActionResult> BorrarTipoForm(int id)
        {
            var tipo = await repositorioCompraTipos.ObtenerPorId(id);
            if (tipo is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(tipo);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarTipo(int compraTipoId)
        {
            var tipo = await repositorioCompraTipos.ObtenerPorId(compraTipoId);
            if (tipo is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioCompraTipos.Borrar(usuarioId, compraTipoId);
            return RedirectToAction("Tipos");
        }

        [HttpGet]
        public IActionResult CrearFilamento()
        {
            return View(null);
        }

        [HttpPost]
        async public Task<IActionResult> CrearFilamento(FilamentoTipo filamento)
        {
            if (!ModelState.IsValid)
            {
                return View(filamento);
            }

            await repositorioFilamentoTipos.Crear(filamento);
            return RedirectToAction("Filamentos");
        }

        [HttpGet]
        public async Task<IActionResult> EditarFilamento(int id)
        {
            var filamento = await repositorioFilamentoTipos.ObtenerPorId(id);
            if (filamento is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(filamento);
        }

        [HttpPost]
        public async Task<IActionResult> EditarFilamento(FilamentoTipo filamentoEditar)
        {
            if (!ModelState.IsValid)
            {
                return View(filamentoEditar);
            }

            var filamento = await repositorioFilamentoTipos.ObtenerPorId(filamentoEditar.FilamentoTipoId);
            if (filamento is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioFilamentoTipos.Actualizar(usuarioId, filamentoEditar);
            return RedirectToAction("Filamentos");
        }

        [HttpGet]
        public async Task<IActionResult> BorrarFilamentoForm(int id)
        {
            var filamento = await repositorioFilamentoTipos.ObtenerPorId(id);
            if (filamento is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(filamento);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarFilamento(int filamentoTipoId)
        {
            var filamento = await repositorioFilamentoTipos.ObtenerPorId(filamentoTipoId);
            if (filamento is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioFilamentoTipos.Borrar(usuarioId, filamentoTipoId);
            return RedirectToAction("Filamentos");
        }

        [HttpGet]
        public IActionResult CrearCategoria()
        {
            return View(null);
        }

        [HttpPost]
        async public Task<IActionResult> CrearCategoria(CompraCategoria categoria)
        {
            if (!ModelState.IsValid)
            {
                return View(categoria);
            }

            await repositorioCompraCategorias.Crear(categoria);
            return RedirectToAction("Categorias");
        }

        [HttpGet]
        public async Task<IActionResult> EditarCategoria(int id)
        {
            var categoria = await repositorioCompraCategorias.ObtenerPorId(id);
            if (categoria is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(categoria);
        }

        [HttpPost]
        public async Task<IActionResult> EditarCategoria(CompraCategoria categoriaEditar)
        {
            if (!ModelState.IsValid)
            {
                return View(categoriaEditar);
            }

            var categoria = await repositorioCompraCategorias.ObtenerPorId(categoriaEditar.CompraCategoriaId);
            if (categoria is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioCompraCategorias.Actualizar(usuarioId, categoriaEditar);
            return RedirectToAction("Categorias");
        }

        [HttpGet]
        public async Task<IActionResult> BorrarCategoriaForm(int id)
        {
            var categoria = await repositorioCompraCategorias.ObtenerPorId(id);
            if (categoria is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            return View(categoria);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarCategoria(int compraCategoriaId)
        {
            var categoria = await repositorioCompraCategorias.ObtenerPorId(compraCategoriaId);
            if (categoria is null)
            {
                return RedirectToAction("NoEncontrado", "Home");
            }

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioCompraCategorias.Borrar(usuarioId, compraCategoriaId);
            return RedirectToAction("Categorias");
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerTipos()
        {
            var tipos = await repositorioCompraTipos.ObtenerTodos();
            return tipos.Select(x => new SelectListItem(x.Nombre, x.CompraTipoId.ToString()));
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerFilamentos()
        {
            var filamentos = await repositorioFilamentoTipos.ObtenerTodos();
            return filamentos.Select(x => new SelectListItem(x.Nombre, x.FilamentoTipoId.ToString()));
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerCategorias()
        {
            var categorias = await repositorioCompraCategorias.ObtenerTodos();
            return categorias.Select(x => new SelectListItem(x.Nombre, x.CompraCategoriaId.ToString()));
        }
    }
}
