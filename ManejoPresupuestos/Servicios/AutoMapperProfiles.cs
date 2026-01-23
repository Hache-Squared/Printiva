using AutoMapper;
using ManejoPresupuestos.Models;

namespace ManejoPresupuestos.Servicios
{
    public class AutoMapperProfiles : Profile
    {
        public AutoMapperProfiles()
        {
            CreateMap<Cuenta, CuentaCreacionViewModel>();
            CreateMap<TransaccionActualizacionViewModel, Transaccion>().ReverseMap(); //configura la conversion en ambas posiciones 
            CreateMap<Inventario, InventarioCreacionViewModel>();
            CreateMap<Producto, ProductoCreacionViewModel>();
            CreateMap<Compra, CompraCreacionViewModel>();
            CreateMap<Venta, VentaCreacionViewModel>();
            CreateMap<Pedido, PedidoCreacionViewModel>()
                .ForMember(d => d.Items, opt => opt.Ignore())
                .ForMember(d => d.Clientes, opt => opt.Ignore())
                .ForMember(d => d.Estatus, opt => opt.Ignore());

            CreateMap<PedidoItem, PedidoItemCreacionViewModel>();
        }
    }
}
